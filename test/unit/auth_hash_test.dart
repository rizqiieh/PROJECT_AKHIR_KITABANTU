import 'package:flutter_test/flutter_test.dart';
import 'package:kitabantu/core/utils/hash_utils.dart';
import 'package:kitabantu/data/local/secure_storage_service.dart';

void main() {
  group('1. Unit Test: Hashing Password SHA-256 & Verifikasi Salt (RF-001 / Bab 12)', () {
    test('generateSalt harus menghasilkan 32 karakter hex acak', () {
      final salt1 = HashUtils.generateSalt();
      final salt2 = HashUtils.generateSalt();

      expect(salt1.length, equals(32));
      expect(salt2.length, equals(32));
      expect(salt1, isNot(equals(salt2))); // Harus acak dan unik
    });

    test('hashPassword harus deterministik dengan password dan salt yang sama', () {
      const password = 'PasswordRahasia123';
      const salt = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';

      final hash1 = HashUtils.hashPassword(password, salt);
      final hash2 = HashUtils.hashPassword(password, salt);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 panjangnya 64 karakter hex
    });

    test('verifyPassword berhasil memvalidasi password benar dan menolak password salah', () {
      const password = 'MySecurePassword!';
      final salt = HashUtils.generateSalt();
      final correctHash = HashUtils.hashPassword(password, salt);

      // Password benar harus lolos
      expect(HashUtils.verifyPassword(password, salt, correctHash), isTrue);

      // Password salah harus ditolak
      expect(HashUtils.verifyPassword('WrongPassword', salt, correctHash), isFalse);

      // Salt salah harus ditolak
      final differentSalt = HashUtils.generateSalt();
      expect(HashUtils.verifyPassword(password, differentSalt, correctHash), isFalse);
    });

    test('Logika Session Timeout 1 Menit (60 Detik)', () {
      expect(SecureStorageService.sessionTimeoutSeconds, equals(60));

      final now = DateTime.now().millisecondsSinceEpoch;
      final recentActive = now - (30 * 1000); // 30 detik lalu (< 60 detik)
      final expiredActive = now - (65 * 1000); // 65 detik lalu (>= 60 detik)

      // Selisih < 60 detik belum expired
      final isRecentExpired = (now - recentActive) >= (SecureStorageService.sessionTimeoutSeconds * 1000);
      expect(isRecentExpired, isFalse);

      // Selisih >= 60 detik sudah expired
      final isOldExpired = (now - expiredActive) >= (SecureStorageService.sessionTimeoutSeconds * 1000);
      expect(isOldExpired, isTrue);
    });
  });
}
