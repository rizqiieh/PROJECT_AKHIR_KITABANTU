import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/data/remote/currency_api_service.dart';
import 'package:kitabantu/data/remote/prayer_api_service.dart';


class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── State Konverter Mata Uang ──
  final _amountCtrl = TextEditingController(text: '100000');
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  Map<String, double> _rates = CurrencyUtils.defaultRatesToIdr;
  bool _isLoadingRates = false;

  // ── State Multi-Zona Waktu & Sholat ──
  final Map<String, Map<String, dynamic>?> _zonePrayers = {};
  bool _isLoadingZones = false;
  String _gpsStatus = 'Mendeteksi lokasi...';
  String _currentLocalZone = '-';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRates();
    _fetchAllZoneData(); // Tarik data 5 negara saat layar dibuka
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

  Future<void> _fetchAllZoneData() async {
    setState(() {
      _isLoadingZones = true;
      _gpsStatus = 'Mendapatkan sinyal GPS...';
    });

    // 1. Deteksi Zona Waktu Saat Ini
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    if (offsetHours == 7) _currentLocalZone = 'WIB (UTC+7)';
    else if (offsetHours == 8) _currentLocalZone = 'WITA (UTC+8)';
    else if (offsetHours == 9) _currentLocalZone = 'WIT (UTC+9)';
    else _currentLocalZone = 'UTC${offsetHours >= 0 ? '+' : ''}$offsetHours';

    // 2. Deteksi GPS (Untuk status saja)
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _gpsStatus = 'Lokasi Akurat: Lat ${pos.latitude.toStringAsFixed(3)}, Lng ${pos.longitude.toStringAsFixed(3)}';
    } catch (e) {
      _gpsStatus = 'GPS tidak aktif / izin ditolak';
    }

    // 3. Tarik API Waktu Sholat 5 Kota Perwakilan Sekaligus
    dynamic wibRes;
    dynamic witaRes;
    dynamic witRes;
    dynamic uaeRes;
    dynamic londonRes;

    try {
      wibRes = await PrayerApiService.instance.fetchPrayerTimesByCity('Jakarta', 'Indonesia');
      witaRes = await PrayerApiService.instance.fetchPrayerTimesByCity('Makassar', 'Indonesia');
      witRes = await PrayerApiService.instance.fetchPrayerTimesByCity('Jayapura', 'Indonesia');
      uaeRes = await PrayerApiService.instance.fetchPrayerTimesByCity('Dubai', 'United Arab Emirates');
      londonRes = await PrayerApiService.instance.fetchPrayerTimesByCity('London', 'United Kingdom');
    } catch (_) {}

    if (mounted) {
      setState(() {
        _zonePrayers['WIB'] = wibRes;
        _zonePrayers['WITA'] = witaRes;
        _zonePrayers['WIT'] = witRes;
        _zonePrayers['UAE'] = uaeRes;
        _zonePrayers['London'] = londonRes;
        _isLoadingZones = false;
      });
    }
  }

  // Fungsi konversi jam real-time berdasarkan zona
  String _getZoneTime(int utcOffset) {
    final utcNow = DateTime.now().toUtc();
    final zoneTime = utcNow.add(Duration(hours: utcOffset));
    return "${zoneTime.hour.toString().padLeft(2, '0')}:${zoneTime.minute.toString().padLeft(2, '0')}";
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
        title: const Text('Konverter & Zona Sholat'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.currency_exchange), text: 'Kurs Mata Uang'),
            Tab(icon: Icon(Icons.public), text: 'Zona Sholat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrencyTab(),
          _buildMultiZoneTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Tab 1: Konverter Mata Uang (Tetap Sama)
  // ══════════════════════════════════════════════════════
  Widget _buildCurrencyTab() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    double result = 0.0;
    try {
      result = CurrencyUtils.convert(amount: amount, fromCurrency: _fromCurrency, toCurrency: _toCurrency, ratesToIdr: _rates);
    } catch (_) {}

    final allConverted = CurrencyUtils.convertIdrToAll(
      _fromCurrency == 'IDR' ? amount : CurrencyUtils.convert(amount: amount, fromCurrency: _fromCurrency, toCurrency: 'IDR', ratesToIdr: _rates),
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
              const Text('Kalkulasi Nilai Tukar:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _isLoadingRates ? null : _fetchRates,
                icon: _isLoadingRates ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync, size: 16),
                label: const Text('Perbarui Kurs', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Jumlah Nominal', prefixText: '$_fromCurrency '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _fromCurrency,
                  decoration: const InputDecoration(labelText: 'Dari'),
                  items: ['IDR', 'USD', 'EUR', 'GBP', 'AED'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _fromCurrency = val); },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
                onPressed: () { setState(() { final temp = _fromCurrency; _fromCurrency = _toCurrency; _toCurrency = temp; }); },
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _toCurrency,
                  decoration: const InputDecoration(labelText: 'Ke'),
                  items: ['IDR', 'USD', 'EUR', 'GBP', 'AED'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _toCurrency = val); },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Hasil Konversi:', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(CurrencyUtils.formatCurrency(result, _toCurrency), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${CurrencyUtils.formatCurrency(amount, _fromCurrency)} = ${CurrencyUtils.formatCurrency(result, _toCurrency)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Konversi Serempak ke 5 Mata Uang:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          _currencyRow('🇮🇩 Rupiah Indonesia (IDR):', CurrencyUtils.formatIdr(allConverted['IDR'] ?? 0)),
          _currencyRow('🇺🇸 Dolar Amerika (USD):', CurrencyUtils.formatCurrency(allConverted['USD'] ?? 0, 'USD')),
          _currencyRow('🇪🇺 Euro Uni Eropa (EUR):', CurrencyUtils.formatCurrency(allConverted['EUR'] ?? 0, 'EUR')),
          _currencyRow('🇬🇧 Pound Sterling Britania (GBP):', CurrencyUtils.formatCurrency(allConverted['GBP'] ?? 0, 'GBP')),
          _currencyRow('🇦🇪 Dirham Uni Emirat Arab (AED):', CurrencyUtils.formatCurrency(allConverted['AED'] ?? 0, 'AED')),
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
  //  Tab 2: Zona Waktu & Waktu Sholat 5 Wilayah
  // ══════════════════════════════════════════════════════
  Widget _buildMultiZoneTab() {
    return RefreshIndicator(
      onRefresh: _fetchAllZoneData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Info Lokasi & Zona Pengguna
            Card(
              color: AppColors.primary.withValues(alpha: 0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.primary, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: AppColors.primary),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Status Lokasi Anda', style: TextStyle(fontWeight: FontWeight.bold))),
                        if (_isLoadingZones)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Zona Waktu:', style: TextStyle(fontSize: 12)),
                        Text(_currentLocalZone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GPS:', style: TextStyle(fontSize: 12)),
                        Text(_gpsStatus, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Perbandingan Jam & Sholat 5 Zona:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Membangun 5 Card Zona
            _zoneCard('🇮🇩 WIB (Jakarta)', 'Asia/Jakarta (UTC+7)', 7, 'WIB', Icons.location_city),
            _zoneCard('🇮🇩 WITA (Makassar)', 'Asia/Makassar (UTC+8)', 8, 'WITA', Icons.wb_sunny),
            _zoneCard('🇮🇩 WIT (Jayapura)', 'Asia/Jayapura (UTC+9)', 9, 'WIT', Icons.wb_twilight),
            _zoneCard('🇦🇪 UAE (Dubai)', 'Asia/Dubai (UTC+4)', 4, 'UAE', Icons.mosque),
            _zoneCard('🇬🇧 London (Inggris)', 'Eropa/London (UTC+0)', 0, 'London', Icons.apartment),
          ],
        ),
      ),
    );
  }

  Widget _zoneCard(String title, String subtitle, int utcOffset, String key, IconData icon) {
    final prayers = _zonePrayers[key];
    final timeStr = _getZoneTime(utcOffset);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Bagian Atas: Ikon, Nama Zona, dan Jam Besar
            Row(
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
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
              ],
            ),
            // Bagian Bawah: Baris Jadwal Sholat
            if (prayers != null) ...[
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniPrayer('Subuh', prayers['Fajr']),
                  _miniPrayer('Dzuhur', prayers['Dhuhr']),
                  _miniPrayer('Ashar', prayers['Asr']),
                  _miniPrayer('Maghrib', prayers['Maghrib']),
                  _miniPrayer('Isya', prayers['Isha']),
                ],
              ),
            ] else if (_isLoadingZones) ...[
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Memuat jadwal sholat...', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
              )
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Gagal memuat jadwal', style: TextStyle(fontSize: 11, color: Colors.red, fontStyle: FontStyle.italic)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _miniPrayer(String label, String? time) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(time ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}