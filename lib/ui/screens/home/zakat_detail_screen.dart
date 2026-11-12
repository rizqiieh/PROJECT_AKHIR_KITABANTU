import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/core/services/notification_service.dart';

class ZakatDetailScreen extends ConsumerStatefulWidget {
  const ZakatDetailScreen({super.key});

  @override
  ConsumerState<ZakatDetailScreen> createState() => _ZakatDetailScreenState();
}

class _ZakatDetailScreenState extends ConsumerState<ZakatDetailScreen> {
  void _showZakatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ZakatModalContent(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Sucikan Harta dengan Zakat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Image (Placeholder menyerupai desain)
                 Image.network(
  'https://baznaskotatangsel.org/assets/uploads/campaigns/0479cf5d50ec0039.jpg',
  width: double.infinity,
  height: 180,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) => Container(
    height: 180,
    color: const Color(0xFF1E824C),
    alignment: Alignment.center,
    child: const Icon(Icons.image_not_supported, color: Colors.white, size: 40),
  ),
),
                  
                  // Info Lembaga
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF168D4C), size: 28),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'KitaBantu Zakat',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Identitas lembaga terverifikasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Tunaikan Zakat Maal Sucikan Harta & Diri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tombol Sticky Bawah
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _showZakatModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B3B2B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Zakat',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  Bottom Sheet Konten Zakat
// ══════════════════════════════════════════════════════

class _ZakatModalContent extends StatefulWidget {
  final WidgetRef ref;
  const _ZakatModalContent({required this.ref});

  @override
  State<_ZakatModalContent> createState() => _ZakatModalContentState();
}

class _ZakatModalContentState extends State<_ZakatModalContent> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  String _selectedJenis = 'Zakat Maal';
  double _selectedNominal = 0;
  final _customNominalCtrl = TextEditingController();
  bool _isProcessing = false;

  final List<String> _jenisZakatOptions = [
    'Zakat Maal',
    'Zakat Penghasilan',
    'Zakat Fitrah',
    'Zakat Tabungan',
  ];

  @override
  void dispose() {
    _customNominalCtrl.dispose();
    super.dispose();
  }

  void _processPayment() async {
    final nominalToPay = _selectedNominal;
    if (nominalToPay < 10000) return;

    final user = widget.ref.read(authProvider).user;
    if (user == null) return;

    if (user.balance < nominalToPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo Kantong Amanah tidak mencukupi (${_currencyFormat.format(user.balance)}).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final success = await widget.ref.read(authProvider.notifier).deductBalance(
          nominalToPay,
          description: 'Pembayaran $_selectedJenis',
          referenceId: 'ZKT-${DateTime.now().millisecondsSinceEpoch}',
        );

    setState(() => _isProcessing = false);

  if (mounted) {
      if (success) {
        // Panggil notifikasi zakat
        NotificationService.instance.showZakatSuccessNotification(
          jenisZakat: _selectedJenis,
          amountFormatted: _currencyFormat.format(nominalToPay),
        );

        // 1. Tutup modal pilihan nominal di bawah
        Navigator.pop(context);
        
        // 2. Tampilkan Pop-up Sukses di tengah layar
        showDialog(
          context: context,
          barrierDismissible: false, // Cegah tutup dialog kalau klik di luar
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 72),
                  const SizedBox(height: 16),
                  const Text(
                    'Alhamdulillah!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_selectedJenis sebesar ${_currencyFormat.format(nominalToPay)} berhasil ditunaikan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Tutup dialog ini
                        Navigator.pop(context);       // Kembali ke halaman beranda
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Kembali ke Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memproses pembayaran zakat.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // Ambil padding bawah agar input tidak tertutup keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isButtonEnabled = _selectedNominal >= 10000 && !_isProcessing;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset > 0 ? bottomInset + 16 : 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Center(
              child: Text(
                'Tunaikan Zakat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            
            // Jenis Zakat
            const Text('Jenis Zakat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jenisZakatOptions.map((jenis) {
                final isSelected = _selectedJenis == jenis;
                return ChoiceChip(
                  label: Text(jenis),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedJenis = jenis);
                    }
                  },
                  selectedColor: const Color(0xFF1B4D30),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Pilih Nominal
            const Text('Pilih Nominal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            _buildNominalOption('😊', 50000),
            const SizedBox(height: 8),
            _buildNominalOption('🥰', 100000),
            const SizedBox(height: 8),
            _buildNominalOption('😇', 250000),
            const SizedBox(height: 20),

            // Nominal Lainnya
            const Text('Nominal Donasi Lainnya', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _customNominalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) {
                setState(() {
                  _selectedNominal = double.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Min. zakat sebesar Rp10.000',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Tombol Lanjut
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled ? const Color(0xFF43A047) : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Lanjut pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNominalOption(String emoji, double amount) {
    final isSelected = _selectedNominal == amount && _customNominalCtrl.text.isEmpty;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedNominal = amount;
          _customNominalCtrl.clear(); // Hapus input manual jika memilih opsi tetap
          FocusScope.of(context).unfocus();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4D30) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currencyFormat.format(amount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}