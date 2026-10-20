import 'package:flutter_test/flutter_test.dart';
import 'package:kitabantu/core/utils/ledger_utils.dart';

void main() {
  group('2. Unit Test: Perhitungan & Integritas Rantai Hash Ledger (RF-007 / Bab 12)', () {
    test('calculateEntryHash menghasilkan hash SHA-256 yang valid dan konsisten', () {
      final hash = LedgerUtils.calculateEntryHash(
        blockIndex: 1,
        donationId: 'don-001',
        campaignId: 'camp-001',
        description: 'Donasi Bencana Banjir',
        amount: 100000.0,
        previousHash: LedgerUtils.genesisPreviousHash,
        createdAt: '2026-10-21T10:00:00Z',
      );

      expect(hash.length, equals(64));
    });

    test('verifyChain memvalidasi rantai blok yang utuh dan valid', () {
      // Buat rantai 3 blok yang valid
      const time1 = '2026-10-21T10:00:00Z';
      final hash1 = LedgerUtils.calculateEntryHash(
        blockIndex: 0,
        donationId: 'don-genesis',
        campaignId: 'camp-genesis',
        description: 'Blok Awal Transparansi',
        amount: 0.0,
        previousHash: LedgerUtils.genesisPreviousHash,
        createdAt: time1,
      );

      const time2 = '2026-10-21T10:05:00Z';
      final hash2 = LedgerUtils.calculateEntryHash(
        blockIndex: 1,
        donationId: 'don-001',
        campaignId: 'camp-001',
        description: 'Donasi Panti Asuhan',
        amount: 250000.0,
        previousHash: hash1,
        createdAt: time2,
      );

      const time3 = '2026-10-21T10:10:00Z';
      final hash3 = LedgerUtils.calculateEntryHash(
        blockIndex: 2,
        donationId: 'don-002',
        campaignId: 'camp-002',
        description: 'Donasi Bencana Gempa',
        amount: 500000.0,
        previousHash: hash2,
        createdAt: time3,
      );

      final chain = [
        LedgerBlockData(
          blockIndex: 0,
          donationId: 'don-genesis',
          campaignId: 'camp-genesis',
          description: 'Blok Awal Transparansi',
          amount: 0.0,
          previousHash: LedgerUtils.genesisPreviousHash,
          entryHash: hash1,
          createdAt: time1,
        ),
        LedgerBlockData(
          blockIndex: 1,
          donationId: 'don-001',
          campaignId: 'camp-001',
          description: 'Donasi Panti Asuhan',
          amount: 250000.0,
          previousHash: hash1,
          entryHash: hash2,
          createdAt: time2,
        ),
        LedgerBlockData(
          blockIndex: 2,
          donationId: 'don-002',
          campaignId: 'camp-002',
          description: 'Donasi Bencana Gempa',
          amount: 500000.0,
          previousHash: hash2,
          entryHash: hash3,
          createdAt: time3,
        ),
      ];

      final result = LedgerUtils.verifyChain(chain);
      expect(result.isValid, isTrue);
      expect(result.brokenIndex, isNull);
    });

    test('verifyChain mendeteksi manipulasi data (tampering) pada salah satu blok', () {
      final hash1 = LedgerUtils.calculateEntryHash(
        blockIndex: 0,
        donationId: 'don-genesis',
        campaignId: 'camp-genesis',
        description: 'Genesis',
        amount: 0.0,
        previousHash: LedgerUtils.genesisPreviousHash,
        createdAt: '2026-10-21T10:00:00Z',
      );

      final hash2 = LedgerUtils.calculateEntryHash(
        blockIndex: 1,
        donationId: 'don-001',
        campaignId: 'camp-001',
        description: 'Donasi Asli Rp 100.000',
        amount: 100000.0,
        previousHash: hash1,
        createdAt: '2026-10-21T10:05:00Z',
      );

      // Simulasi penyerang mengubah nominal amount dari 100.000 menjadi 999.999 tanpa menghitung ulang hash
      final tamperedChain = [
        LedgerBlockData(
          blockIndex: 0,
          donationId: 'don-genesis',
          campaignId: 'camp-genesis',
          description: 'Genesis',
          amount: 0.0,
          previousHash: LedgerUtils.genesisPreviousHash,
          entryHash: hash1,
          createdAt: '2026-10-21T10:00:00Z',
        ),
        LedgerBlockData(
          blockIndex: 1,
          donationId: 'don-001',
          campaignId: 'camp-001',
          description: 'Donasi Asli Rp 100.000',
          amount: 999999.0, // <-- Diubah secara ilegal!
          previousHash: hash1,
          entryHash: hash2,
          createdAt: '2026-10-21T10:05:00Z',
        ),
      ];

      final result = LedgerUtils.verifyChain(tamperedChain);
      expect(result.isValid, isFalse);
      expect(result.brokenIndex, equals(1));
    });
  });
}
