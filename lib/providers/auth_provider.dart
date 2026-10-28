import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:kitabantu/core/utils/hash_utils.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/local/secure_storage_service.dart';
import 'package:kitabantu/data/models/user_model.dart';
import 'package:kitabantu/data/models/wallet_transaction_model.dart';

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

  // ── Cek sesi saat aplikasi dimulai (RF-001 & Session Timeout) ──

  /// Memeriksa apakah ada sesi aktif di Secure Storage.
  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);

    final hasSession = await _secure.hasActiveSession();
    if (!hasSession) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    final isExpired = await _secure.isSessionExpired();
    if (isExpired) {
      await _secure.clearSession();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage:
            'Sesi telah berakhir karena tidak ada aktivitas selama 1 menit. Silakan login kembali.',
      );
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

    await _secure.updateLastActive();
    state = state.copyWith(status: AuthStatus.authenticated, user: user);
  }

  // ── Registrasi (RF-001) ──

  /// Mendaftarkan pengguna baru dengan SHA-256 + salt secara instan.
  Future<String?> register({
    required String fullName,
    required String username,
    String? email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    if (await _db.isUsernameTaken(username)) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Username "$username" sudah terdaftar.',
      );
      return state.errorMessage;
    }

    final salt = HashUtils.generateSalt();
    final passwordHash = HashUtils.hashPassword(password, salt);

    final user = UserModel(
      fullName: fullName,
      username: username,
      email: email,
      passwordHash: passwordHash,
      salt: salt,
      biometricEnabled: true,
      balance: 1000000.0,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      final id = await _db.insertUser(user);
      final savedUser = user.copyWith(id: id);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: savedUser,
      );

      unawaited(Future.wait([
        _secure.saveSession(
          userId: id,
          username: username,
          fullName: fullName,
          biometricEnabled: true,
        ),
        _secure.updateBiometricEnabled(
          true,
          userId: id,
          username: username,
        ),
        _secure.setOnboardingCompleted(true),
      ]));

      return null;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Gagal mendaftar: $e',
      );
      return state.errorMessage;
    }
  }

  // ── Login dengan Password (Mendukung Username atau Email) ──

  /// Login menggunakan identifier (bisa username atau email) dan password.
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    if (kIsWeb) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: UserModel(
          id: 1,
          username: username,
          fullName: 'Pengguna Web',
          passwordHash: '',
          salt: '',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      return null;
    }

    state = state.copyWith(status: AuthStatus.loading);

    // Cari akun berdasarkan username ATAU email
    final user = await _db.getUserByIdentifier(username);
    if (user == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Email atau Username tidak ditemukan.',
      );
      return state.errorMessage;
    }

    if (!HashUtils.verifyPassword(password, user.salt, user.passwordHash)) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Kata sandi salah.',
      );
      return state.errorMessage;
    }

    state = state.copyWith(status: AuthStatus.authenticated, user: user);

    await _secure.saveSession(
      userId: user.id!,
      username: user.username,
      fullName: user.fullName,
      biometricEnabled: user.biometricEnabled,
      avatarPath: user.avatarPath,
    );

    return null;
  }

  // ── Reset Password ──

  Future<String?> resetPassword({
    required String username,
    required String newPassword,
  }) async {
    final user = await _db.getUserByIdentifier(username);
    if (user == null) {
      return 'Akun "$username" tidak ditemukan di sistem.';
    }

    final newSalt = HashUtils.generateSalt();
    final newPasswordHash = HashUtils.hashPassword(newPassword, newSalt);

    final updated = await _db.updatePassword(user.username, newPasswordHash, newSalt);
    if (updated > 0) {
      return null;
    } else {
      return 'Gagal memperbarui kata sandi. Silakan coba lagi.';
    }
  }

  // ── Login dengan Biometrik (RF-002) ──

  Future<bool> canUseBiometric() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<String?> loginWithBiometric() async {
    state = state.copyWith(status: AuthStatus.loading);

    final canUse = await canUseBiometric();
    if (!canUse) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Sensor biometrik tidak tersedia di perangkat ini.',
      );
      return state.errorMessage;
    }

    bool isBiometricActive = await _secure.isBiometricEnabled();
    int? targetUserId =
        await _secure.getBiometricUserId() ?? await _secure.getSessionUserId();

    if (!isBiometricActive || targetUserId == null) {
      final bioUser = await _db.getLastUserWithBiometric();
      if (bioUser != null && bioUser.id != null) {
        isBiometricActive = true;
        targetUserId = bioUser.id;
        await _secure.updateBiometricEnabled(
          true,
          userId: bioUser.id,
          username: bioUser.username,
        );
      }
    }

    if (!isBiometricActive || targetUserId == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'Login biometrik belum diaktifkan. Silakan masuk dengan kata sandi terlebih dahulu dan aktifkan biometrik di menu Profil.',
      );
      return state.errorMessage;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari atau wajah untuk masuk ke KitaBantu',
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

      final user = await _db.getUserById(targetUserId);

      if (user == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return 'Akun pengguna belum terdaftar di database lokal.';
      }

      await _secure.saveSession(
        userId: user.id!,
        username: user.username,
        fullName: user.fullName,
        biometricEnabled: true,
        avatarPath: user.avatarPath,
      );

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return null;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Gagal autentikasi biometrik: $e',
      );
      return state.errorMessage;
    }
  }

  // ── Toggle Biometrik (RF-002) ──

  Future<bool> toggleBiometric(bool enable) async {
    final user = state.user;
    if (user == null || user.id == null) return false;

    if (enable) {
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
    await _secure.updateBiometricEnabled(
      enable,
      userId: user.id!,
      username: user.username,
    );

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
      user: user.copyWith(
        avatarPath: path,
        clearAvatar: path == null,
      ),
    );
  }

  // ── Saldo Kantong Amanah & Top Up (SQLite) ──

  Future<bool> topUpBalance(double amount, {String method = 'QRIS'}) async {
    final user = state.user;
    if (user == null || user.id == null || amount <= 0) return false;

    final newBalance = user.balance + amount;
    await _db.updateUserBalance(user.id!, newBalance);
    await _db.insertWalletTransaction(
      WalletTransactionModel(
        userId: user.id!,
        type: 'TOPUP',
        amount: amount,
        description: 'Top Up Kantong Amanah via $method',
        referenceId: 'TOP-${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    state = state.copyWith(
      user: user.copyWith(balance: newBalance),
    );
    return true;
  }

  Future<bool> deductBalance(
    double amount, {
    required String description,
    String? referenceId,
  }) async {
    final user = state.user;
    if (user == null || user.id == null || amount <= 0) return false;
    if (user.balance < amount) return false;

    final newBalance = user.balance - amount;
    await _db.updateUserBalance(user.id!, newBalance);
    await _db.insertWalletTransaction(
      WalletTransactionModel(
        userId: user.id!,
        type: 'DONASI',
        amount: amount,
        description: description,
        referenceId: referenceId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    state = state.copyWith(
      user: user.copyWith(balance: newBalance),
    );
    return true;
  }

  // ── Logout & Session Timeout (RF-003) ──

  Future<void> logout() async {
    await _secure.clearSession();
    state = const AuthState();
  }

  Future<void> logoutDueToInactivity() async {
    await _secure.clearSession();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage:
          'Sesi Anda telah berakhir karena tidak ada aktivitas selama 1 menit.',
    );
  }

  Future<void> recordUserActivity() async {
    if (state.status == AuthStatus.authenticated) {
      await _secure.updateLastActive();
    }
  }
}

// ══════════════════════════════════════════════════════
//  Provider Global
// ══════════════════════════════════════════════════════

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);