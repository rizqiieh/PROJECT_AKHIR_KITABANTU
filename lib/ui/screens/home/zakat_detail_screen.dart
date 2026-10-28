import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../providers/auth_provider.dart';

class ZakatDetailScreen extends ConsumerStatefulWidget {
  const ZakatDetailScreen({super.key});

  @override
  ConsumerState<ZakatDetailScreen> createState() => _ZakatDetailScreenState();
}

class _ZakatDetailScreenState extends ConsumerState<ZakatDetailScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initNotification();
  }

  // Inisialisasi Notifikasi Lokal
  Future<void> _initNotification() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  // Munculkan Notifikasi Berhasil Zakat
  Future<void> _showSuccessNotification(int amount) async {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final formattedAmount = currencyFormatter.format(amount);

    const androidDetails = AndroidNotificationDetails(
      'zakat_channel',
      'Transaksi Zakat',
      channelDescription: 'Notifikasi konfirmasi pembayaran zakat KitaBantu',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Zakat Berhasil Ditunaikan! 🤲',
      'Alhamdulillah, zakat sebesar $formattedAmount telah tercatat.',
      notificationDetails,
    );
  }

  Future<void> _kirimZakatKeDatabase(int amount, String zakatType) async {
    setState(() => _isLoading = true);
    final authState = ref.read(authProvider);
    final currentUser = authState.user;

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('zakat_transactions').insert({
        'user_id': currentUser?.id?.toString() ?? 'anonymous',
        'donor_name': currentUser?.fullName ?? currentUser?.username ?? 'Hamba Allah',
        'amount': amount,
        'zakat_type': zakatType, // Menggunakan tipe yang dipilih user
        'status': 'success',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _showSuccessNotification(amount);

      if (mounted) {
        final currency = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pembayaran Zakat Berhasil!'),
            content: Text(
              'Alhamdulillah, $zakatType sebesar ${currency.format(amount)} berhasil disalurkan dan tersimpan di database.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Selesai'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencatat zakat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _showNominalSheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    int selectedAmount = 0;
    String selectedZakatType = 'Zakat Maal';

    final List<String> zakatTypes = [
      'Zakat Maal',
      'Zakat Penghasilan',
      'Zakat Fitrah',
      'Zakat Tabungan',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isValid = selectedAmount >= 10000;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Tunaikan Zakat',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Pilihan Jenis Zakat ---
                    const Text('Jenis Zakat', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: zakatTypes.map((type) {
                        final isTypeSelected = selectedZakatType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isTypeSelected,
                          selectedColor: const Color(0xFF26533C),
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isTypeSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                            fontWeight: isTypeSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedZakatType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // --- Pilihan Nominal Cepat ---
                    const Text('Pilih Nominal', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildNominalOption(
                      emoji: '😊',
                      amountText: 'Rp50.000',
                      isSelected: selectedAmount == 50000,
                      onTap: () {
                        setSheetState(() {
                          selectedAmount = 50000;
                          amountController.text = '50000';
                        });
                      },
                    ),
                    _buildNominalOption(
                      emoji: '🥰',
                      amountText: 'Rp100.000',
                      isSelected: selectedAmount == 100000,
                      onTap: () {
                        setSheetState(() {
                          selectedAmount = 100000;
                          amountController.text = '100000';
                        });
                      },
                    ),
                    _buildNominalOption(
                      emoji: '😇',
                      amountText: 'Rp250.000',
                      isSelected: selectedAmount == 250000,
                      onTap: () {
                        setSheetState(() {
                          selectedAmount = 250000;
                          amountController.text = '250000';
                        });
                      },
                    ),

                    const SizedBox(height: 12),
                    const Text('Nominal Donasi Lainnya', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final parsed = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        setSheetState(() => selectedAmount = parsed);
                      },
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        hintText: '0',
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0, bottom: 16),
                      child: Text(
                        'Min. zakat sebesar Rp10.000',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),

                    // Tombol Bayar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isValid
                            ? () {
                                Navigator.pop(context);
                                _kirimZakatKeDatabase(selectedAmount, selectedZakatType);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isValid ? const Color(0xFF26533C) : Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Lanjut pembayaran',
                          style: TextStyle(
                            color: isValid ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildNominalOption({
    required String emoji,
    required String amountText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBF6F0) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF26533C) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? const Color(0xFF26533C) : Colors.black87,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isSelected ? const Color(0xFF26533C) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sucikan Harta dengan Zakat',
            style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              'https://bisasedekah.id/wp-content/uploads/2026/04/Slider-Zakat.png',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: const Color(0xFF26533C),
                child: const Center(
                  child: Icon(Icons.volunteer_activism,
                      size: 50, color: Colors.white70),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF26533C),
                        child: Icon(Icons.verified, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('KitaBantu Zakat',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Identitas lembaga terverifikasi',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tunaikan Zakat Maal Sucikan Harta & Diri',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _showNominalSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Zakat',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}