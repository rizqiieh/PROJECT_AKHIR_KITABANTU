import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Utilitas hashing password SHA-256 + salt (RF-001).
///
/// Sesuai spesifikasi Bab 8.1:
///   password_hash = SHA-256(password + salt)
///   salt = 32 karakter random hex
class HashUtils {
  HashUtils._();

  static final _random = Random.secure();

  /// Menghasilkan salt acak 32 karakter heksadesimal.
  static String generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hash password menggunakan SHA-256 dengan salt.
  ///
  /// Rumus: SHA-256(password + salt)
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi password terhadap hash yang tersimpan.
  ///
  /// Menghitung ulang SHA-256(password + salt) dan membandingkan
  /// dengan [storedHash].
  static bool verifyPassword(
    String password,
    String salt,
    String storedHash,
  ) {
    final computedHash = hashPassword(password, salt);
    return computedHash == storedHash;
  }
}
