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

  // ── Kunci penyimpanan ──
  static const _keyUserId = 'session_user_id';
  static const _keyUsername = 'session_username';
  static const _keyFullName = 'session_full_name';
  static const _keyBiometricEnabled = 'session_biometric_enabled';
  static const _keyAvatarPath = 'session_avatar_path';
  static const _keyLastActive = 'session_last_active';

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

  /// Mengecek apakah biometrik diaktifkan pada sesi ini.
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Mengambil path avatar dari sesi aktif.
  Future<String?> getSessionAvatarPath() async {
    return _storage.read(key: _keyAvatarPath);
  }

  /// Memperbarui status biometrik di sesi.
  Future<void> updateBiometricEnabled(bool enabled) async {
    await _storage.write(
        key: _keyBiometricEnabled, value: enabled.toString());
  }

  /// Memperbarui avatar di sesi.
  Future<void> updateAvatarPath(String? path) async {
    if (path != null) {
      await _storage.write(key: _keyAvatarPath, value: path);
    } else {
      await _storage.delete(key: _keyAvatarPath);
    }
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
  //  Hapus Sesi (Logout)
  // ══════════════════════════════════════════════════════

  /// Menghapus seluruh data sesi saat logout.
  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
