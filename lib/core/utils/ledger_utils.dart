import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilitas Blockchain / Ledger Transparansi Hash-Chain (RF-007 & Bab 12).
class LedgerUtils {
  LedgerUtils._();

  /// Genesis hash konstan untuk blok pertama dalam rantai.
  static const String genesisPreviousHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  /// Menghitung hash SHA-256 dari satu blok ledger.
  ///
  /// String yang di-hash:
  /// `"$blockIndex|$donationId|$campaignId|$description|$amount|$previousHash|$createdAt"`
  static String calculateEntryHash({
    required int blockIndex,
    required String donationId,
    required String campaignId,
    required String description,
    required double amount,
    required String previousHash,
    required String createdAt,
  }) {
    final rawData =
        '$blockIndex|$donationId|$campaignId|$description|${amount.toStringAsFixed(2)}|$previousHash|$createdAt';
    final bytes = utf8.encode(rawData);
    return sha256.convert(bytes).toString();
  }

  /// Memverifikasi integritas seluruh rantai blok ledger (Bab 12 - Unit Test 2).
  ///
  /// Mengembalikan [LedgerVerificationResult]:
  /// - `isValid`: true jika semua hash blok cocok dan rantai tidak terputus.
  /// - `brokenIndex`: index blok yang rusak/termanipulasi jika tidak valid.
  /// - `errorMessage`: deskripsi masalah jika rantai rusak.
  static LedgerVerificationResult verifyChain(List<LedgerBlockData> chain) {
    if (chain.isEmpty) {
      return const LedgerVerificationResult(
        isValid: true,
        message: 'Rantai kosong (belum ada transaksi).',
      );
    }

    for (int i = 0; i < chain.length; i++) {
      final current = chain[i];

      // 1. Cek previous_hash
      if (i == 0) {
        if (current.previousHash != genesisPreviousHash) {
          return LedgerVerificationResult(
            isValid: false,
            brokenIndex: i,
            message:
                'Blok Genesis (Index 0) memiliki previous_hash tidak valid.',
          );
        }
      } else {
        final prev = chain[i - 1];
        if (current.previousHash != prev.entryHash) {
          return LedgerVerificationResult(
            isValid: false,
            brokenIndex: i,
            message:
                'Rantai terputus pada blok $i. previous_hash tidak cocok dengan hash blok sebelumnya.',
          );
        }
      }

      // 2. Cek keaslian entry_hash dengan menghitung ulang
      final recalculatedHash = calculateEntryHash(
        blockIndex: current.blockIndex,
        donationId: current.donationId,
        campaignId: current.campaignId,
        description: current.description,
        amount: current.amount,
        previousHash: current.previousHash,
        createdAt: current.createdAt,
      );

      if (recalculatedHash != current.entryHash) {
        return LedgerVerificationResult(
          isValid: false,
          brokenIndex: i,
          message:
              'Data pada blok $i telah dimanipulasi! Hash tersimpan tidak cocok dengan hash kalkulasi ulang.',
        );
      }
    }

    return const LedgerVerificationResult(
      isValid: true,
      message: 'Semua blok valid dan integritas rantai terverifikasi 100%!',
    );
  }
}

/// Struktur data ringan untuk verifikasi rantai ledger.
class LedgerBlockData {
  final int blockIndex;
  final String donationId;
  final String campaignId;
  final String description;
  final double amount;
  final String previousHash;
  final String entryHash;
  final String createdAt;

  const LedgerBlockData({
    required this.blockIndex,
    required this.donationId,
    required this.campaignId,
    required this.description,
    required this.amount,
    required this.previousHash,
    required this.entryHash,
    required this.createdAt,
  });
}

/// Hasil verifikasi rantai ledger.
class LedgerVerificationResult {
  final bool isValid;
  final int? brokenIndex;
  final String message;

  const LedgerVerificationResult({
    required this.isValid,
    this.brokenIndex,
    required this.message,
  });
}
