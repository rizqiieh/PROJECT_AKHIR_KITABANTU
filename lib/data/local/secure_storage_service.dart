import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Layanan penyimpanan sesi terenkripsi (RF-001 & RF-002).
///
/// Menyimpan informasi sesi login ke Android Keystore / iOS Keychain
/// sehingga aman dari akses langsung dan bertahan saat aplikasi ditutup
/// selama sesi belum kedaluwarsa (inactivity timeout 1 menit).
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Kunci penyimpanan sesi aktif ──
  static const _keyUserId = 'session_user_id';
  static const _keyUsername = 'session_username';
  static const _keyFullName = 'session_full_name';
  static const _keyBiometricEnabled = 'session_biometric_enabled';
  static const _keyAvatarPath = 'session_avatar_path';
  static const _keyLastActive = 'session_last_active';

  // ── Kunci preferensi onboarding aplikasi ──
  static const _keyOnboardingCompleted = 'app_onboarding_completed';

  // ── Kunci kredensial biometrik persisten perangkat (tetap ada meski logout / timeout) ──
  static const _keyBiometricUserId = 'device_biometric_user_id';
  static const _keyBiometricUsername = 'device_biometric_username';

  /// Batas waktu kedaluwarsa sesi jika tidak ada aktivitas (1 menit = 60 detik).
  static const int sessionTimeoutSeconds = 60;

  // ══════════════════════════════════════════════════════
  //  Simpan & Baca Sesi
  // ══════════════════════════════════════════════════════

  /// Menyimpan sesi login setelah autentikasi berhasil.
  Future<void> saveSession({
    required int userId,
    required String username,
    required String fullName,
    required bool biometricEnabled,
    String? avatarPath,
  }) async {
    await _storage.write(key: _keyUserId, value: userId.toString());
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyFullName, value: fullName);
    await _storage.write(
        key: _keyBiometricEnabled,
        value: biometricEnabled.toString());
    await _storage.write(
        key: _keyLastActive,
        value: DateTime.now().millisecondsSinceEpoch.toString());
    if (avatarPath != null) {
      await _storage.write(key: _keyAvatarPath, value: avatarPath);
    }

    // Jika biometrik aktif, simpan juga sebagai kredensial biometrik persisten
    if (biometricEnabled) {
      await _storage.write(key: _keyBiometricUserId, value: userId.toString());
      await _storage.write(key: _keyBiometricUsername, value: username);
    }
  }

  /// Mengecek apakah ada sesi aktif.
  Future<bool> hasActiveSession() async {
    final userId = await _storage.read(key: _keyUserId);
    return userId != null;
  }

  /// Mengambil user ID dari sesi aktif.
  Future<int?> getSessionUserId() async {
    final value = await _storage.read(key: _keyUserId);
    return value != null ? int.tryParse(value) : null;
  }

  /// Mengambil username dari sesi aktif.
  Future<String?> getSessionUsername() async {
    return _storage.read(key: _keyUsername);
  }

  /// Mengambil nama lengkap dari sesi aktif.
  Future<String?> getSessionFullName() async {
    return _storage.read(key: _keyFullName);
  }

  /// Mengecek apakah biometrik diaktifkan pada sesi atau perangkat ini.
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    if (value == 'true') return true;
    final bioUserId = await getBiometricUserId();
    return bioUserId != null;
  }

  /// Mengambil ID user yang terdaftar untuk biometrik perangkat ini.
  Future<int?> getBiometricUserId() async {
    final value = await _storage.read(key: _keyBiometricUserId);
    return value != null ? int.tryParse(value) : null;
  }

  /// Mengambil username yang terdaftar untuk biometrik perangkat ini.
  Future<String?> getBiometricUsername() async {
    return _storage.read(key: _keyBiometricUsername);
  }

  /// Mengambil path avatar dari sesi aktif.
  Future<String?> getSessionAvatarPath() async {
    return _storage.read(key: _keyAvatarPath);
  }

  /// Memperbarui status biometrik di sesi dan kredensial persisten perangkat.
  Future<void> updateBiometricEnabled(bool enabled, {int? userId, String? username}) async {
    await _storage.write(
        key: _keyBiometricEnabled, value: enabled.toString());
    if (enabled) {
      if (userId != null) {
        await _storage.write(key: _keyBiometricUserId, value: userId.toString());
      }
      if (username != null) {
        await _storage.write(key: _keyBiometricUsername, value: username);
      }
    } else {
      await _storage.delete(key: _keyBiometricUserId);
      await _storage.delete(key: _keyBiometricUsername);
    }
  }

  /// Memperbarui avatar di sesi.
  Future<void> updateAvatarPath(String? path) async {
    if (path != null) {
      await _storage.write(key: _keyAvatarPath, value: path);
    } else {
      await _storage.delete(key: _keyAvatarPath);
    }
  }

  /// Mengecek apakah onboarding pengantar telah selesai dilihat.
  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(key: _keyOnboardingCompleted);
    return value == 'true';
  }

  /// Menandai status onboarding selesai.
  Future<void> setOnboardingCompleted([bool completed = true]) async {
    await _storage.write(
      key: _keyOnboardingCompleted,
      value: completed.toString(),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Manajemen Timeout Sesi (Inactivity Timeout 1 Menit)
  // ══════════════════════════════════════════════════════

  /// Memperbarui timestamp aktivitas terakhir sesi (epoch milliseconds).
  Future<void> updateLastActive() async {
    await _storage.write(
      key: _keyLastActive,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Mengambil timestamp aktivitas terakhir dalam millisecondsSinceEpoch.
  Future<int?> getLastActive() async {
    final value = await _storage.read(key: _keyLastActive);
    return value != null ? int.tryParse(value) : null;
  }

  /// Memeriksa apakah sesi telah kedaluwarsa (tidak ada aktivitas >= 1 menit).
  ///
  /// Mengembalikan true jika:
  /// 1. Tidak ada sesi aktif (user ID belum login).
  /// 2. Selisih waktu sekarang dengan aktivitas terakhir >= 60 detik.
  Future<bool> isSessionExpired() async {
    final hasSession = await hasActiveSession();
    if (!hasSession) return true;

    final lastActive = await getLastActive();
    if (lastActive == null) return false;

    final diffMs = DateTime.now().millisecondsSinceEpoch - lastActive;
    return diffMs >= (sessionTimeoutSeconds * 1000);
  }

  // ══════════════════════════════════════════════════════
  //  Hapus Sesi (Logout / Session Timeout)
  // ══════════════════════════════════════════════════════

  /// Menghapus sesi aktif tanpa menghapus kredensial biometrik perangkat.
  /// Kredensial biometrik (_keyBiometricEnabled & _keyBiometricUserId) tetap dipertahankan
  /// agar pengguna dapat masuk kembali menggunakan sidik jari setelah sesi berakhir.
  Future<void> clearSession() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyFullName);
    await _storage.delete(key: _keyAvatarPath);
    await _storage.delete(key: _keyLastActive);
  }

  /// Menghapus seluruh data termasuk kredensial biometrik (reset total).
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
