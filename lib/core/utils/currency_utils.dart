import 'package:intl/intl.dart';

/// Utilitas konversi dan pemformatan mata uang (RF-006 & Bab 12).
///
/// Mendukung 4 mata uang: IDR, USD, EUR, GBP.
class CurrencyUtils {
  CurrencyUtils._();

  /// Kurs nilai tukar default (basis IDR) sebagai fallback saat offline.
  /// 1 Unit Mata Uang Asing = X IDR.
  static const Map<String, double> defaultRatesToIdr = {
    'IDR': 1.0,
    'USD': 16000.0,
    'EUR': 17200.0,
    'GBP': 20500.0,
  };

  /// Format angka ke Rupiah standar: `Rp 50.000`
  static String formatIdr(num amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  /// Format angka sesuai mata uang target.
  static String formatCurrency(num amount, String currencyCode) {
    final code = currencyCode.toUpperCase();
    switch (code) {
      case 'IDR':
        return formatIdr(amount);
      case 'USD':
        return NumberFormat.currency(locale: 'en_US', symbol: '\$ ', decimalDigits: 2)
            .format(amount);
      case 'EUR':
        return NumberFormat.currency(locale: 'de_DE', symbol: '€ ', decimalDigits: 2)
            .format(amount);
      case 'GBP':
        return NumberFormat.currency(locale: 'en_GB', symbol: '£ ', decimalDigits: 2)
            .format(amount);
      default:
        return '$code ${amount.toStringAsFixed(2)}';
    }
  }

  /// Mengonversi nilai dari [fromCurrency] ke [toCurrency].
  ///
  /// Menggunakan [ratesToIdr] (peta 1 Unit Mata Uang = X IDR).
  /// Jika [ratesToIdr] tidak diberikan, memakai kurs default.
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    Map<String, double>? ratesToIdr,
  }) {
    final rates = ratesToIdr ?? defaultRatesToIdr;
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();

    if (from == to) return amount;

    final fromRate = rates[from];
    final toRate = rates[to];

    if (fromRate == null || toRate == null || toRate == 0) {
      throw ArgumentError('Mata uang tidak didukung: $from / $to');
    }

    // Ubah ke IDR dulu (amount * fromRate), lalu bagi dengan toRate
    final amountInIdr = amount * fromRate;
    final convertedAmount = amountInIdr / toRate;

    return convertedAmount;
  }

  /// Menghitung konversi nilai IDR ke semua mata uang sekaligus (IDR, USD, EUR, GBP).
  static Map<String, double> convertIdrToAll(double amountIdr,
      [Map<String, double>? ratesToIdr]) {
    final rates = ratesToIdr ?? defaultRatesToIdr;
    return {
      'IDR': amountIdr,
      'USD': convert(amount: amountIdr, fromCurrency: 'IDR', toCurrency: 'USD', ratesToIdr: rates),
      'EUR': convert(amount: amountIdr, fromCurrency: 'IDR', toCurrency: 'EUR', ratesToIdr: rates),
      'GBP': convert(amount: amountIdr, fromCurrency: 'IDR', toCurrency: 'GBP', ratesToIdr: rates),
    };
  }
}
