import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kitabantu/core/utils/currency_utils.dart';

/// Layanan API Kurs Mata Uang Online
/// Mengambil data kurs real-time gratis (termasuk AED untuk UEA)
class CurrencyApiService {
  CurrencyApiService._();
  static final CurrencyApiService instance = CurrencyApiService._();

  // Menggunakan API baru yang mendukung Dirham (AED) dan mata uang global
  static const String _exchangeApiUrl = 'https://open.er-api.com/v6/latest/IDR';

  /// Mengambil peta kurs terbaru terhadap IDR.
  Future fetchLatestRatesToIdr() async {
    try {
      final response = await http
          .get(Uri.parse(_exchangeApiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;

        // Karena base-nya adalah IDR (1 IDR = x USD),
        // kita membalik rumusnya (1 / x) untuk mencari tahu 1 USD = x IDR
        final usdToIdr = 1 / (rates['USD'] as num).toDouble();
        final eurToIdr = 1 / (rates['EUR'] as num).toDouble();
        final gbpToIdr = 1 / (rates['GBP'] as num).toDouble();
        
        // Tambahan Kurs Dirham UEA
        final aedToIdr = 1 / (rates['AED'] as num).toDouble(); 

        return {
          'IDR': 1.0,
          'USD': usdToIdr,
          'EUR': eurToIdr,
          'GBP': gbpToIdr,
          'AED': aedToIdr, // Dirham sudah masuk!
        };
      }
    } catch (_) {
      // Jika offline atau timeout, lari ke catch
    }

    // Fallback Offline: Gunakan default dari utils, dan sisipkan AED
    final fallbackRates = Map<String, double>.from(CurrencyUtils.defaultRatesToIdr);
    if (!fallbackRates.containsKey('AED')) {
      fallbackRates['AED'] = 4275.0; // Asumsi offline: 1 AED = ~Rp 4.275
    }
    return fallbackRates;
  }
}