import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/core/utils/zakat_calculator_utils.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/models/zakat_history_model.dart';
import 'package:kitabantu/providers/auth_provider.dart';

/// Halaman Kalkulator Zakat (Bab 6 §7 — RF-008).
///
/// Asisten AI zakat sudah dipindah ke tombol mengambang di Beranda
/// (lihat `ui/widgets/ai_chat_sheet.dart`).
class ZakatCalculatorScreen extends ConsumerStatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  ConsumerState<ZakatCalculatorScreen> createState() =>
      _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends ConsumerState<ZakatCalculatorScreen> {
  // ── State Kalkulator Zakat ──
  String _selectedZakatType = 'Penghasilan'; // 'Penghasilan' atau 'Maal'
  final _wealthController = TextEditingController(text: '10000000');
  final _expenseController = TextEditingController(text: '2000000');
  final _goldPriceController =
      TextEditingController(text: '1300000'); // Rp 1.300.000 / gram
  ZakatCalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _calculateZakat();
  }

  void _calculateZakat() {
    final goldPrice = double.tryParse(_goldPriceController.text) ??
        ZakatCalculatorUtils.defaultGoldPricePerGram;

    if (_selectedZakatType == 'Maal') {
      final wealth = double.tryParse(_wealthController.text) ?? 0.0;
      setState(() {
        _result = ZakatCalculatorUtils.calculateZakatMaal(
          totalWealth: wealth,
          goldPrice: goldPrice,
        );
      });
    } else {
      final income = double.tryParse(_wealthController.text) ?? 0.0;
      final expense = double.tryParse(_expenseController.text) ?? 0.0;
      setState(() {
        _result = ZakatCalculatorUtils.calculateZakatPenghasilan(
          monthlyIncome: income,
          monthlyExpense: expense,
          goldPrice: goldPrice,
        );
      });
    }
  }

  @override
  void dispose() {
    _wealthController.dispose();
    _expenseController.dispose();
    _goldPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Zakat'),
      ),
      body: _buildCalculatorTab(),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Kalkulator Zakat Fiqih
  // ══════════════════════════════════════════════════════

  Widget _buildCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pilihan Tipe Zakat ──
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Zakat Penghasilan')),
                  selected: _selectedZakatType == 'Penghasilan',
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedZakatType == 'Penghasilan'
                        ? Colors.white
                        : AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedZakatType = 'Penghasilan');
                      _calculateZakat();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Zakat Maal (Harta)')),
                  selected: _selectedZakatType == 'Maal',
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedZakatType == 'Maal'
                        ? Colors.white
                        : AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedZakatType = 'Maal');
                      _calculateZakat();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Form Input ──
          TextField(
            controller: _wealthController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _selectedZakatType == 'Penghasilan'
                  ? 'Penghasilan Bulanan (Rp)'
                  : 'Total Harta Simpanan / Emas / Tabungan (Rp)',
              prefixText: 'Rp ',
            ),
            onChanged: (_) => _calculateZakat(),
          ),
          if (_selectedZakatType == 'Penghasilan') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _expenseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pengeluaran Pokok Mendesak (Rp)',
                prefixText: 'Rp ',
              ),
              onChanged: (_) => _calculateZakat(),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _goldPriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Estimasi Harga Emas / Gram (Acuan Nisab)',
              prefixText: 'Rp ',
              helperText: 'Standar BAZNAS: 85 gram emas',
            ),
            onChanged: (_) => _calculateZakat(),
          ),
          const SizedBox(height: 20),

          // ── Hasil Perhitungan Nisab & Zakat (RF-008) ──
          if (_result != null) ...[
            Card(
              color: _result!.isWajib
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _result!.isWajib
                          ? 'Kewajiban Zakat (2.5%):'
                          : 'Status Kewajiban Zakat:',
                      style: TextStyle(
                        fontSize: 13,
                        color: _result!.isWajib
                            ? Colors.white70
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _result!.isWajib
                          ? CurrencyUtils.formatIdr(_result!.zakatAmount)
                          : 'Belum Mencapai Nisab',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _result!.isWajib
                            ? Colors.white
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.explanation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: _result!.isWajib
                            ? Colors.white.withValues(alpha: 0.9)
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tombol Simpan Riwayat ke SQLite ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveHistoryToSqlite,
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Simpan Riwayat Hitung (SQLite)'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveHistoryToSqlite() async {
    if (_result == null) return;
    final user = ref.read(authProvider).user;
    final userId = user?.id ?? 1;

    final history = ZakatHistoryModel(
      userId: userId,
      zakatType: _selectedZakatType,
      totalWealth: _result!.totalWealth,
      zakatAmount: _result!.zakatAmount,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.insertZakatHistory(history);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Riwayat Zakat $_selectedZakatType (${CurrencyUtils.formatIdr(_result!.zakatAmount)}) tersimpan di SQLite lokal! ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}