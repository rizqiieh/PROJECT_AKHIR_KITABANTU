import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/data/local/database_helper.dart'; // Sesuaikan import db Anda
import 'package:kitabantu/data/models/ledger_model.dart';   // Sesuaikan import model Anda
import 'payment_success_screen.dart';
import 'package:kitabantu/core/utils/ledger_utils.dart';
class PaymentQrScreen extends StatelessWidget {
  final double amount;
  final String campaignTitle;
  final String campaignImage;
  final bool isAnonymous;

  const PaymentQrScreen({
    super.key,
    required this.amount,
    required this.campaignTitle,
    required this.campaignImage,
    required this.isAnonymous,
  });

  Future<void> _processPayment(BuildContext context) async {
    // Tampilkan loading sebentar
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(const Duration(seconds: 2)); // Simulasi proses bank
    if (!context.mounted) return;
    Navigator.pop(context); // Tutup loading

    // ── INTEGRASI LEDGER (HASH-CHAIN BLOCKCHAIN) ──
    final db = DatabaseHelper.instance;
    final latestBlock = await db.getLatestLedgerEntry();

    final nextIndex = (latestBlock?.blockIndex ?? -1) + 1;
    final prevHash = latestBlock?.entryHash ?? LedgerUtils.genesisPreviousHash;
    final donationId = 'don-${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now().toIso8601String();
    final desc = isAnonymous ? 'Donasi Anonim: $campaignTitle' : 'Donasi QRIS: $campaignTitle';

    final entryHash = LedgerUtils.calculateEntryHash(
      blockIndex: nextIndex,
      donationId: donationId,
      campaignId: 'cmp-qris-01',
      description: desc,
      amount: amount,
      previousHash: prevHash,
      createdAt: createdAt,
    );

    final newBlock = LedgerModel(
      blockIndex: nextIndex,
      donationId: donationId,
      campaignId: 'cmp-qris-01',
      description: desc,
      amount: amount,
      previousHash: prevHash,
      entryHash: entryHash,
      createdAt: createdAt,
    );

    await db.insertLedgerEntry(newBlock);
    
    // Pindah ke layar Sukses
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: amount,
            campaignTitle: campaignTitle,
            campaignImage: campaignImage,
          transactionId: donationId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate string unik untuk QR dummy
    final qrData = "00020101021126570011ID.CO.QRIS.WWW01189360091531234567890214${DateTime.now().millisecondsSinceEpoch}5303360540${amount.toInt()}5802ID5915Kitabantu Donasi6015Yogyakarta6304ABCD";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(79, 130, 104, 1),
        title: const Text('Instruksi Pembayaran', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Biru
            Container(
              color:Color.fromRGBO(79, 130, 104, 1),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Batas waktu pembayaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Sisa 15 menit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                    child: const Text('00:15:00', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            
            // Area QR Code
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scan QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Image.asset('assets/images/qris_logo.png', height: 20, errorBuilder: (_,__,___) => const Text('QRIS')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Kotak QR
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color:Color.fromRGBO(79, 130, 104, 1), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Simpan QR Code', style: TextStyle(color:Color.fromRGBO(79, 130, 104, 1), fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 32),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total donasi'),
                      Text(CurrencyUtils.formatIdr(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tombol Simulasi Bayar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(79, 130, 104, 1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => _processPayment(context),
                      child: const Text('Cek status pembayaran', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}