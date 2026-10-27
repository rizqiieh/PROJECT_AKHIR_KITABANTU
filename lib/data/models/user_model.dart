/// Model data pengguna lokal (Bab 8.1 — tabel `users`).
class UserModel {
  final int? id;
  final String fullName;
  final String username;
  final String passwordHash;
  final String salt;
  final String? avatarPath;
  final bool biometricEnabled;
  final double balance;
  final String createdAt;

  const UserModel({
    this.id,
    required this.fullName,
    required this.username,
    required this.passwordHash,
    required this.salt,
    this.avatarPath,
    this.biometricEnabled = true,
    this.balance = 1000000.0,
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
      biometricEnabled: (map['biometric_enabled'] as int?) != 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 1000000.0,
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
      'balance': balance,
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
    bool clearAvatar = false,
    bool? biometricEnabled,
    double? balance,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
