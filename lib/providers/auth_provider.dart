import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kitabantu/core/utils/hash_utils.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/local/secure_storage_service.dart';
import 'package:kitabantu/data/models/user_model.dart';

// ══════════════════════════════════════════════════════
//  State
// ══════════════════════════════════════════════════════

/// Status autentikasi global.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// State immutable untuk autentikasi.
class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// ══════════════════════════════════════════════════════
//  Notifier
// ══════════════════════════════════════════════════════

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _db = DatabaseHelper.instance;
  final _secure = SecureStorageService.instance;
  final _localAuth = LocalAuthentication();

  // ── Cek sesi saat aplikasi dimulai ──

  /// Memeriksa apakah ada sesi aktif di Secure Storage.
  /// Dipanggil dari SplashScreen.
  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);

    final hasSession = await _secure.hasActiveSession();
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final userId = await _secure.getSessionUserId();
    if (userId == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final user = await _db.getUserById(userId);
    if (user == null) {
      await _secure.clearSession();
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(status: AuthStatus.authenticated, user: user);
  }

  // ── Registrasi (RF-001) ──

  /// Mendaftarkan pengguna baru dengan SHA-256 + salt.
  Future<String?> register({
    required String fullName,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    // Cek duplikat username
    if (await _db.isUsernameTaken(username)) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Username "$username" sudah terdaftar.',
      );
      return state.errorMessage;
    }

    // Hash password
    final salt = HashUtils.generateSalt();
    final passwordHash = HashUtils.hashPassword(password, salt);

    final user = UserModel(
      fullName: fullName,
      username: username,
      passwordHash: passwordHash,
      salt: salt,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      final id = await _db.insertUser(user);
      final savedUser = user.copyWith(id: id);

      // Langsung login setelah register
      await _secure.saveSession(
        userId: id,
        username: username,
        fullName: fullName,
        biometricEnabled: false,
      );

      state = state.copyWith(
          status: AuthStatus.authenticated, user: savedUser);
      return null; // null = sukses
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Gagal mendaftar: $e',
      );
      return state.errorMessage;
    }
  }

  // ── Login dengan Password (RF-001) ──

  /// Login menggunakan username dan password.
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final user = await _db.getUserByUsername(username);
    if (user == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Username tidak ditemukan.',
      );
      return state.errorMessage;
    }

    if (!HashUtils.verifyPassword(password, user.salt, user.passwordHash)) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Password salah.',
      );
      return state.errorMessage;
    }

    await _secure.saveSession(
      userId: user.id!,
      username: user.username,
      fullName: user.fullName,
      biometricEnabled: user.biometricEnabled,
      avatarPath: user.avatarPath,
    );

    state = state.copyWith(status: AuthStatus.authenticated, user: user);
    return null;
  }

  // ── Login dengan Biometrik (RF-002) ──

  /// Memeriksa apakah perangkat mendukung biometrik.
  Future<bool> canUseBiometric() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Login menggunakan sidik jari / wajah.
  /// Hanya berhasil jika sesi sebelumnya masih ada di Secure Storage
  /// dan biometrik diaktifkan.
  Future<String?> loginWithBiometric() async {
    state = state.copyWith(status: AuthStatus.loading);

    final hasSession = await _secure.hasActiveSession();
    final biometricOn = await _secure.isBiometricEnabled();

    if (!hasSession || !biometricOn) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Sesi biometrik tidak tersedia. Silakan login dengan password.',
      );
      return state.errorMessage;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verifikasi identitas untuk masuk ke KitaBantu',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Autentikasi biometrik dibatalkan.',
        );
        return state.errorMessage;
      }

      // Biometrik berhasil → ambil user dari DB
      final userId = await _secure.getSessionUserId();
      if (userId == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return 'Sesi tidak ditemukan.';
      }

      final user = await _db.getUserById(userId);
      if (user == null) {
        await _secure.clearSession();
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return 'Akun tidak ditemukan.';
      }

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return null;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Gagal biometrik: $e',
      );
      return state.errorMessage;
    }
  }

  // ── Toggle Biometrik (RF-002) ──

  /// Mengaktifkan atau menonaktifkan login biometrik.
  Future<bool> toggleBiometric(bool enable) async {
    final user = state.user;
    if (user == null || user.id == null) return false;

    if (enable) {
      // Validasi biometrik dulu sebelum mengaktifkan
      final canUse = await canUseBiometric();
      if (!canUse) return false;

      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Verifikasi untuk mengaktifkan login biometrik',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        if (!authenticated) return false;
      } catch (_) {
        return false;
      }
    }

    await _db.updateBiometricEnabled(user.id!, enable);
    await _secure.updateBiometricEnabled(enable);

    state = state.copyWith(
      user: user.copyWith(biometricEnabled: enable),
    );
    return true;
  }

  // ── Update Avatar ──

  Future<void> updateAvatar(String? path) async {
    final user = state.user;
    if (user == null || user.id == null) return;

    await _db.updateAvatarPath(user.id!, path);
    await _secure.updateAvatarPath(path);

    state = state.copyWith(
      user: user.copyWith(avatarPath: path),
    );
  }

  // ── Logout (RF-003) ──

  /// Menghapus sesi dan mengeluarkan pengguna.
  Future<void> logout() async {
    await _secure.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ══════════════════════════════════════════════════════
//  Provider Global
// ══════════════════════════════════════════════════════

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
