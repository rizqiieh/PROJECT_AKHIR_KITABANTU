import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String campaignTitle;
  final String campaignImage;
  final String transactionId;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.campaignTitle,
    required this.campaignImage,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(79, 130, 104, 1),
        title: const Text('Donasi', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text('Terima kasih!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Donasimu telah diterima dan akan segera disalurkan', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            // Kartu Rincian
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _detailRow('Tanggal', DateFormat('dd MMMM yyyy - HH:mm', 'id_ID').format(DateTime.now())),
                  _detailRow('Metode pembayaran', 'QRIS'),
                  _detailRow('ID donasi', '#$transactionId'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status', style: TextStyle(color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color:Color.fromRGBO(79, 130, 104, 1)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('Berhasil', style: TextStyle(color:Color.fromRGBO(79, 130, 104, 1), fontSize: 12)),
                      )
                    ],
                  ),
                  const Divider(height: 32),
                  
                  // Info Kampanye
                  Row(
                    children: [
                     ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: campaignImage.startsWith('http')
      ? Image.network(
          campaignImage,
          width: 100,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 100,
            height: 60,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
          ),
        )
      : Image.asset(
          campaignImage,
          width: 100,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 100,
            height: 60,
            color: Colors.grey.shade300,
            child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
          ),
        ),
),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(campaignTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromRGBO(79, 130, 104, 1),
                                minimumSize: const Size(100, 30),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                              child: const Text('Selesai', style: TextStyle(color: Colors.white, fontSize: 12)),
                            )
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // Rincian Angka
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total donasi'),
                      Text(CurrencyUtils.formatIdr(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nominal donasi', style: TextStyle(color: Color.fromRGBO(79, 130, 104, 1))),
                      Text(CurrencyUtils.formatIdr(amount), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color:Color.fromRGBO(79, 130, 104, 1))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}