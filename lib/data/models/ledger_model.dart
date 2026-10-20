import 'package:kitabantu/core/utils/ledger_utils.dart';

/// Model data blok ledger transparansi (Bab 8.2 — tabel `ledger_entries`).
class LedgerModel {
  final int blockIndex;
  final String donationId;
  final String campaignId;
  final String description;
  final double amount;
  final String previousHash;
  final String entryHash;
  final String createdAt;

  const LedgerModel({
    required this.blockIndex,
    required this.donationId,
    required this.campaignId,
    required this.description,
    required this.amount,
    required this.previousHash,
    required this.entryHash,
    required this.createdAt,
  });

  /// Konversi ke `LedgerBlockData` untuk diverifikasi oleh `LedgerUtils.verifyChain()`.
  LedgerBlockData toBlockData() {
    return LedgerBlockData(
      blockIndex: blockIndex,
      donationId: donationId,
      campaignId: campaignId,
      description: description,
      amount: amount,
      previousHash: previousHash,
      entryHash: entryHash,
      createdAt: createdAt,
    );
  }

  factory LedgerModel.fromMap(Map<String, dynamic> map) {
    return LedgerModel(
      blockIndex: (map['block_index'] as num).toInt(),
      donationId: (map['donation_id'] ?? '').toString(),
      campaignId: (map['campaign_id'] ?? '').toString(),
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      previousHash: map['previous_hash'] as String,
      entryHash: map['entry_hash'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'block_index': blockIndex,
      'donation_id': donationId,
      'campaign_id': campaignId,
      'description': description,
      'amount': amount,
      'previous_hash': previousHash,
      'entry_hash': entryHash,
      'created_at': createdAt,
    };
  }
}
