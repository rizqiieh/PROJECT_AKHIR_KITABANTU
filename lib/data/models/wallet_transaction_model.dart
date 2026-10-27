/// Model data transaksi dompet / Kantong Amanah lokal.
class WalletTransactionModel {
  final int? id;
  final int userId;
  final String type; // 'TOPUP' atau 'DONASI' atau 'ZAKAT'
  final double amount;
  final String description;
  final String? referenceId;
  final String createdAt;

  const WalletTransactionModel({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map) {
    return WalletTransactionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      referenceId: map['reference_id'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'reference_id': referenceId,
      'created_at': createdAt,
    };
  }
}
