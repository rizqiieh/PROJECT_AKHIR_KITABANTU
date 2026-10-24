import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Memproses gambar menggunakan On-Device AI Computer Vision
  Future<Map<String, dynamic>> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    String rawText = recognizedText.text;
    double? detectedNominal;

    // Regex untuk mendeteksi nominal angka (Rp, angka berformat ribuan)
    final RegExp nominalRegex = RegExp(r'(?:Rp\.?|IDR)?\s*([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]+)?)');

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final match = nominalRegex.firstMatch(line.text);
        if (match != null) {
          String cleanStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
          double? val = double.tryParse(cleanStr);
          // Ambil nominal yang realistis (misal di atas 10.000)
          if (val != null && val >= 10000) {
            if (detectedNominal == null || val > detectedNominal) {
              detectedNominal = val;
            }
          }
        }
      }
    }

    return {
      'rawText': rawText,
      'nominal': detectedNominal ?? 0.0,
    };
  }

  void dispose() {
    _textRecognizer.close();
  }
}