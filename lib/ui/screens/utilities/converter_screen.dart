import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/core/utils/time_zone_utils.dart';
import 'package:kitabantu/data/remote/currency_api_service.dart';

/// Layar Konverter Mata Uang & Zona Waktu (Bab 6 §4 — RF-006).
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── State Konverter Mata Uang ──
  final _amountCtrl = TextEditingController(text: '100000');
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  Map<String, double> _rates = CurrencyUtils.defaultRatesToIdr;
  bool _isLoadingRates = false;

  // ── State Konverter Waktu ──
  DateTime _selectedDateTime = DateTime.now();
  String _sourceZone = 'WIB';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    setState(() => _isLoadingRates = true);
    final fetched = await CurrencyApiService.instance.fetchLatestRatesToIdr();
    if (mounted) {
      setState(() {
        _rates = fetched;
        _isLoadingRates = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konverter Kurs & Waktu'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.currency_exchange), text: 'Kurs Mata Uang'),
            Tab(icon: Icon(Icons.schedule), text: 'Zona Waktu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrencyTab(),
          _buildTimeZoneTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Tab 1: Konverter Mata Uang
  // ══════════════════════════════════════════════════════

  Widget _buildCurrencyTab() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    double result = 0.0;
    try {
      result = CurrencyUtils.convert(
        amount: amount,
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        ratesToIdr: _rates,
      );
    } catch (_) {}

    final allConverted = CurrencyUtils.convertIdrToAll(
      _fromCurrency == 'IDR'
          ? amount
          : CurrencyUtils.convert(
              amount: amount,
              fromCurrency: _fromCurrency,
              toCurrency: 'IDR',
              ratesToIdr: _rates,
            ),
      _rates,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kalkulasi Nilai Tukar:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _isLoadingRates ? null : _fetchRates,
                icon: _isLoadingRates
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 16),
                label: const Text('Perbarui Kurs', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Input Nominal ──
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jumlah Nominal',
              prefixText: '$_fromCurrency ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // ── Selector Dari & Ke ──
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _fromCurrency,
                  decoration: const InputDecoration(labelText: 'Dari'),
                  items: ['IDR', 'USD', 'EUR', 'GBP']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _fromCurrency = val);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                onPressed: () {
                  setState(() {
                    final temp = _fromCurrency;
                    _fromCurrency = _toCurrency;
                    _toCurrency = temp;
                  });
                },
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _toCurrency,
                  decoration: const InputDecoration(labelText: 'Ke'),
                  items: ['IDR', 'USD', 'EUR', 'GBP']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _toCurrency = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Hasil Konversi Utama ──
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Hasil Konversi:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyUtils.formatCurrency(result, _toCurrency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyUtils.formatCurrency(amount, _fromCurrency)} = ${CurrencyUtils.formatCurrency(result, _toCurrency)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Ringkasan Nilai dalam Semua Mata Uang ──
          const Text('Konversi Serempak ke 4 Mata Uang:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          _currencyRow('🇮🇩 Rupiah Indonesia (IDR):',
              CurrencyUtils.formatIdr(allConverted['IDR'] ?? 0)),
          _currencyRow('🇺🇸 Dolar Amerika (USD):',
              CurrencyUtils.formatCurrency(allConverted['USD'] ?? 0, 'USD')),
          _currencyRow('🇪🇺 Euro Uni Eropa (EUR):',
              CurrencyUtils.formatCurrency(allConverted['EUR'] ?? 0, 'EUR')),
          _currencyRow('🇬🇧 Pound Sterling Britania (GBP):',
              CurrencyUtils.formatCurrency(allConverted['GBP'] ?? 0, 'GBP')),
        ],
      ),
    );
  }

  Widget _currencyRow(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Tab 2: Konverter Zona Waktu
  // ══════════════════════════════════════════════════════

  Widget _buildTimeZoneTab() {
    // Ubah _selectedDateTime ke UTC berdasarkan sourceZone dulu
    final localTzDateTime = TimeZoneUtils.convertToZone(_selectedDateTime, _sourceZone);
    final allZones = TimeZoneUtils.formatAllFourZones(localTzDateTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Waktu Acuan:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // ── Card Pemilih Waktu ──
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID')
                              .format(_selectedDateTime),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar,
                            color: AppColors.primary),
                        onPressed: _pickDateTime,
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Text('Zona Waktu Asal: ',
                          style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _sourceZone,
                        items: ['WIB', 'WITA', 'WIT', 'London']
                            .map((z) => DropdownMenuItem(
                                  value: z,
                                  child: Text(z,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _sourceZone = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Hasil Konversi 4 Zona Waktu Serempak (RF-006) ──
          const Text('Waktu Serempak di 4 Zona:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _zoneCard('🇮🇩 WIB (Waktu Indonesia Barat)', 'Asia/Jakarta (UTC+7)',
              allZones['WIB'] ?? '', Icons.location_city),
          _zoneCard('🇮🇩 WITA (Waktu Indonesia Tengah)', 'Asia/Makassar (UTC+8)',
              allZones['WITA'] ?? '', Icons.sunny),
          _zoneCard('🇮🇩 WIT (Waktu Indonesia Timur)', 'Asia/Jayapura (UTC+9)',
              allZones['WIT'] ?? '', Icons.wb_twilight),
          _zoneCard('🇬🇧 London (UK - DST Terhitung)', 'Europe/London (BST/GMT)',
              allZones['London'] ?? '', Icons.apartment),
        ],
      ),
    );
  }

  Widget _zoneCard(String title, String subtitle, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Text(
              time.split(', ').last,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
}
