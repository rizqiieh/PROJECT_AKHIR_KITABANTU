import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/core/utils/time_zone_utils.dart';
import 'package:kitabantu/providers/campaign_provider.dart';

/// Halaman Ledger Transparansi Hash-Chain Blockchain (Bab 6 §8 — RF-007).
class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(ledgerProvider);
    final verification = ledgerState.verification;
    final entries = ledgerState.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger Transparansi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang',
            onPressed: () => ref.read(ledgerProvider.notifier).loadLedger(),
          ),
        ],
      ),
      body: ledgerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Banner Status Integritas Rantai (Hijau / Merah) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: verification.isValid
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      Icon(
                        verification.isValid
                            ? Icons.verified_user
                            : Icons.gpp_bad,
                        color: verification.isValid
                            ? AppColors.success
                            : AppColors.error,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              verification.isValid
                                  ? 'Integritas Rantai: VALID'
                                  : 'Integritas Rantai: RUSAK!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: verification.isValid
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              verification.message,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          foregroundColor: verification.isValid
                              ? AppColors.success
                              : AppColors.error,
                          side: BorderSide(
                            color: verification.isValid
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(ledgerProvider.notifier)
                              .verifyChainIntegrity();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(verification.isValid
                                  ? 'Verifikasi selesai: Seluruh blok valid ✓'
                                  : 'Peringatan: Integritas data tidak cocok!'),
                              backgroundColor: verification.isValid
                                  ? AppColors.success
                                  : AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.shield, size: 16),
                        label: const Text('Cek Ulang',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),

                // ── Info Header ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Blok: ${entries.length}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Text(
                        'Algoritma: SHA-256 (Append-Only)',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // ── Daftar Blok Rantai ──
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (ctx, index) {
                      final item = entries[index];
                      final isGenesis = item.blockIndex == 0;
                      final isLast = index == entries.length - 1;
                      final timeDate = DateTime.tryParse(item.createdAt) ??
                          DateTime.now();
                      final formattedTime =
                          TimeZoneUtils.formatInZone(timeDate, 'WIB');

                      return Column(
                        children: [
                          Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isGenesis
                                    ? AppColors.secondary
                                    : AppColors.divider,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isGenesis
                                              ? AppColors.secondary
                                              : AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isGenesis
                                              ? 'GENESIS #0'
                                              : 'BLOK #${item.blockIndex}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        formattedTime,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  if (item.amount > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyUtils.formatIdr(item.amount),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                  const Divider(height: 16),
                                  _hashRow('Previous Hash:', item.previousHash),
                                  const SizedBox(height: 4),
                                  _hashRow('Entry Hash:', item.entryHash,
                                      highlight: true),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                children: const [
                                  Icon(Icons.arrow_downward,
                                      size: 18, color: AppColors.primary),
                                  Text('LINKED',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary)),
                                ],
                              ),
                            )
                          else
                            const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _hashRow(String label, String hash, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          hash,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: highlight ? AppColors.primaryDark : AppColors.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
