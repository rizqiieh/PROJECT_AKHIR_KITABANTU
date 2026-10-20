/// Model data riwayat kalkulasi zakat (Bab 8.1 — tabel `zakat_history`).
class ZakatHistoryModel {
  final int? id;
  final int userId;
  final String zakatType; // 'Penghasilan' atau 'Maal'
  final double totalWealth;
  final double zakatAmount;
  final String createdAt;

  const ZakatHistoryModel({
    this.id,
    required this.userId,
    required this.zakatType,
    required this.totalWealth,
    required this.zakatAmount,
    required this.createdAt,
  });

  factory ZakatHistoryModel.fromMap(Map<String, dynamic> map) {
    return ZakatHistoryModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      zakatType: map['zakat_type'] as String,
      totalWealth: (map['total_wealth'] as num).toDouble(),
      zakatAmount: (map['zakat_amount'] as num).toDouble(),
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'zakat_type': zakatType,
      'total_wealth': totalWealth,
      'zakat_amount': zakatAmount,
      'created_at': createdAt,
    };
  }
}
