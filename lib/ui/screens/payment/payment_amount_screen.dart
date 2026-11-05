import 'package:flutter/material.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'payment_qr_screen.dart';

class PaymentAmountScreen extends StatefulWidget {
  final String campaignTitle;
  final String campaignImage;

  const PaymentAmountScreen({
    super.key,
    required this.campaignTitle,
    required this.campaignImage,
  });

  @override
  State<PaymentAmountScreen> createState() => _PaymentAmountScreenState();
}

class _PaymentAmountScreenState extends State<PaymentAmountScreen> {
  final _amountCtrl = TextEditingController(text: '10000');
  bool _isAnonymous = false;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Nominal Donasi')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Kampanye
           // Banner Kampanye
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.campaignImage.startsWith('http')
                      ? Image.network(
                          widget.campaignImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade400),
                        )
                      : Image.asset(
                          widget.campaignImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade400),
                        ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      widget.campaignTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input Nominal
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Metode Pembayaran (Statis: QRIS)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/qris_logo.png', height: 24, errorBuilder: (_,__,___) => const Text('QRIS', style: TextStyle(fontWeight: FontWeight.bold))),
                            const SizedBox(width: 12),
                            const Text('QRIS'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(''),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Opsi Anonim
                  SwitchListTile(
                    title: const Text('Sembunyikan nama saya (Donasi Anonim)', style: TextStyle(fontSize: 14)),
                    value: _isAnonymous,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  // Kolom Doa
                  const Text('Sertakan doa dan dukungan (opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis doa untuk penggalang dana...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Donasi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  CurrencyUtils.formatIdr(amount),
                  style: const TextStyle(color: Color.fromRGBO(79, 130, 104, 1), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
  backgroundColor:Color.fromRGBO(79, 130, 104, 1), // <-- Kurang tanda koma di sini
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentQrScreen(
                      amount: amount,
                      campaignTitle: widget.campaignTitle,
                      campaignImage: widget.campaignImage,
                      isAnonymous: _isAnonymous,
                    ),
                  ),
                );
              },
              child: const Text('Lanjut pembayaran', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}