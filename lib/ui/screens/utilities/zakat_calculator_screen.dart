import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/core/utils/zakat_calculator_utils.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/models/zakat_history_model.dart';
import 'package:kitabantu/data/remote/gemini_ai_service.dart';
import 'package:kitabantu/providers/auth_provider.dart';

/// Halaman Kalkulator & Asisten AI Zakat (Bab 6 §7 — RF-008).
class ZakatCalculatorScreen extends ConsumerStatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  ConsumerState<ZakatCalculatorScreen> createState() =>
      _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends ConsumerState<ZakatCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── State Kalkulator Zakat ──
  String _selectedZakatType = 'Penghasilan'; // 'Penghasilan' atau 'Maal'
  final _wealthController = TextEditingController(text: '10000000');
  final _expenseController = TextEditingController(text: '2000000');
  final _goldPriceController =
      TextEditingController(text: '1300000'); // Rp 1.300.000 / gram
  ZakatCalculationResult? _result;

  // ── State Chat AI ──
  final _chatInputCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text':
          'Assalamu\'alaikum! Saya Asisten AI Zakat KitaBantu. Tanyakan seputar nisab emas, tata cara zakat profesi/maal, atau 8 golongan penerima (asnaf).'
    }
  ];
  bool _isAiThinking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    _wealthController.dispose();
    _expenseController.dispose();
    _goldPriceController.dispose();
    _chatInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator & AI Zakat'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.calculate), text: 'Kalkulator Fiqih'),
            Tab(icon: Icon(Icons.smart_toy), text: 'Konsultasi AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalculatorTab(),
          _buildAiChatTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Tab 1: Kalkulator Zakat Fiqih
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

  // ══════════════════════════════════════════════════════
  //  Tab 2: Tanya Jawab Asisten AI Zakat (Gemini)
  // ══════════════════════════════════════════════════════

  Widget _buildAiChatTab() {
    return Column(
      children: [
        // ── Quick Topic Chips ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('Berapa nisab emas?'),
                _buildQuickChip('Siapa saja 8 asnaf?'),
                _buildQuickChip('Cara zakat profesi'),
                _buildQuickChip('Zakat tabungan & deposito'),
              ],
            ),
          ),
        ),

        // ── Daftar Pesan Chat ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (ctx, idx) {
              final msg = _messages[idx];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(2),
                      bottomRight: isUser
                          ? const Radius.circular(2)
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.onSurface,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (_isAiThinking)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Asisten AI sedang menyusun jawaban...',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),

        // ── Input Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Tanyakan fiqih zakat ke AI...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onSubmitted: (val) => _sendChatMessage(val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () => _sendChatMessage(_chatInputCtrl.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        onPressed: () => _sendChatMessage(text),
      ),
    );
  }

  Future<void> _sendChatMessage(String question) async {
    final q = question.trim();
    if (q.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': q});
      _chatInputCtrl.clear();
      _isAiThinking = true;
    });

    final answer = await GeminiAiService.instance.askZakatQuestion(q);

    if (mounted) {
      setState(() {
        _isAiThinking = false;
        _messages.add({'role': 'ai', 'text': answer});
      });
    }
  }
}
