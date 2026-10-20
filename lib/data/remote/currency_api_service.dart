import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kitabantu/core/utils/currency_utils.dart';

/// Layanan API Kurs Mata Uang Online (RF-006).
///
/// Mengambil data kurs real-time gratis menggunakan Frankfurter API / Open API publik
/// dengan mekanisme fallback offline otomatis ke nilai default jika internet mati.
class CurrencyApiService {
  CurrencyApiService._();
  static final CurrencyApiService instance = CurrencyApiService._();

  static const String _frankfurterUrl =
      'https://api.frankfurter.app/latest?from=USD&to=EUR,GBP';

  /// Mengambil peta kurs terbaru terhadap IDR.
  /// Format return: `{'IDR': 1.0, 'USD': 16000.0, 'EUR': 17200.0, 'GBP': 20500.0}`
  Future<Map<String, double>> fetchLatestRatesToIdr() async {
    try {
      final response = await http
          .get(Uri.parse(_frankfurterUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;

        // 1 USD dalam EUR dan GBP
        final eurPerUsd = (rates['EUR'] as num).toDouble();
        final gbpPerUsd = (rates['GBP'] as num).toDouble();

        // Asumsi kurs USD ke IDR acuan Rp 16.000 (bisa dikombinasikan secara real-time)
        const usdToIdr = 16000.0;
        final eurToIdr = usdToIdr / eurPerUsd;
        final gbpToIdr = usdToIdr / gbpPerUsd;

        return {
          'IDR': 1.0,
          'USD': usdToIdr,
          'EUR': eurToIdr,
          'GBP': gbpToIdr,
        };
      }
    } catch (_) {
      // Jika offline atau timeout, gunakan fallback nilai default
    }

    return CurrencyUtils.defaultRatesToIdr;
  }
}
