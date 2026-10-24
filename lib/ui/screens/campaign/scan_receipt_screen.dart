import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kitabantu/core/services/ocr_scanner_service.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrScannerService _ocrService = OcrScannerService();
  File? _image;
  bool _isLoading = false;
  double _detectedNominal = 0;
  String _detectedText = '';

  Future<void> _pickAndScanImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      setState(() {
        _image = File(picked.path);
        _isLoading = true;
        _detectedText = '';
        _detectedNominal = 0;
      });

      final result = await _ocrService.scanReceipt(_image!);

      setState(() {
        _isLoading = false;
        _detectedNominal = (result['nominal'] as num).toDouble();
        _detectedText = result['rawText'] as String;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memindai: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Smart Scan Nota Medis/Pangan'),
        backgroundColor: const Color(0xFF2F6533),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner_outlined, size: 54, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Foto kuitansi/nota kebutuhan bantuan'),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F6533),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _pickAndScanImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _pickAndScanImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF2F6533)),
                      SizedBox(height: 12),
                      Text('AI sedang menganalisis gambar...'),
                    ],
                  ),
                ),
              )
            else if (_detectedText.isNotEmpty)
              Card(
                color: const Color(0xFFE8F5E9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFC8E6C9)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF2F6533), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Hasil Analisis Machine Learning (OCR):',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2F6533)),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (_detectedNominal > 0) ...[
                        const Text(
                          'Nominal Terdeteksi:',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          'Rp ${_detectedNominal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2F6533),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F6533),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Gunakan Nominal Ini'),
                            onPressed: () {
                              Navigator.pop(context, _detectedNominal);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const Text('Teks Terbaca pada Nota:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _detectedText,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}