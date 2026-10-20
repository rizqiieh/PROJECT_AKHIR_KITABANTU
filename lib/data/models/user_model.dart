/// Model data pengguna lokal (Bab 8.1 — tabel `users`).
class UserModel {
  final int? id;
  final String fullName;
  final String username;
  final String passwordHash;
  final String salt;
  final String? avatarPath;
  final bool biometricEnabled;
  final String createdAt;

  const UserModel({
    this.id,
    required this.fullName,
    required this.username,
    required this.passwordHash,
    required this.salt,
    this.avatarPath,
    this.biometricEnabled = false,
    required this.createdAt,
  });

  /// Buat UserModel dari Map hasil query SQLite.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      avatarPath: map['avatar_path'] as String?,
      biometricEnabled: (map['biometric_enabled'] as int?) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  /// Konversi ke Map untuk INSERT ke SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'avatar_path': avatarPath,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'created_at': createdAt,
    };
  }

  /// Buat salinan dengan field yang diubah.
  UserModel copyWith({
    int? id,
    String? fullName,
    String? username,
    String? passwordHash,
    String? salt,
    String? avatarPath,
    bool? biometricEnabled,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      avatarPath: avatarPath ?? this.avatarPath,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
