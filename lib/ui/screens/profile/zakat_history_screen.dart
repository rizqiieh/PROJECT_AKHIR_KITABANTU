import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/models/zakat_history_model.dart';
import 'package:kitabantu/providers/auth_provider.dart';

/// Layar Riwayat Hitung Zakat (RF-008 — SQLite).
class ZakatHistoryScreen extends ConsumerStatefulWidget {
  const ZakatHistoryScreen({super.key});

  @override
  ConsumerState<ZakatHistoryScreen> createState() => _ZakatHistoryScreenState();
}

class _ZakatHistoryScreenState extends ConsumerState<ZakatHistoryScreen> {
  List<ZakatHistoryModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = ref.read(authProvider).user;
    final userId = user?.id ?? 1;
    final list = await DatabaseHelper.instance.getZakatHistory(userId);
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Hitung Zakat (SQLite)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Riwayat Perhitungan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hitung zakat Anda di menu Kalkulator Zakat, lalu simpan ke database lokal.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (ctx, idx) {
                    final item = _history[idx];
                    final date = DateTime.tryParse(item.createdAt) ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Zakat ${item.zakatType}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Harta / Gaji:',
                                    style: TextStyle(fontSize: 12)),
                                Text(
                                  CurrencyUtils.formatIdr(item.totalWealth),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Kewajiban Zakat (2.5%):',
                                    style: TextStyle(fontSize: 12)),
                                Text(
                                  CurrencyUtils.formatIdr(item.zakatAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
