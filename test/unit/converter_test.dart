import 'package:flutter_test/flutter_test.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/core/utils/time_zone_utils.dart';

void main() {
  group('3. Unit Test: Konversi Mata Uang & Zona Waktu (RF-006 / Bab 12)', () {
    test('Konversi mata uang IDR, USD, EUR, GBP akurat sesuai kurs', () {
      const customRates = {
        'IDR': 1.0,
        'USD': 16000.0,
        'EUR': 17000.0,
        'GBP': 20000.0,
      };

      // 1. IDR ke USD: Rp 160.000 -> $ 10.00
      final usd = CurrencyUtils.convert(
        amount: 160000.0,
        fromCurrency: 'IDR',
        toCurrency: 'USD',
        ratesToIdr: customRates,
      );
      expect(usd, closeTo(10.0, 0.001));

      // 2. USD ke IDR: $ 5.0 -> Rp 80.000
      final idrFromUsd = CurrencyUtils.convert(
        amount: 5.0,
        fromCurrency: 'USD',
        toCurrency: 'IDR',
        ratesToIdr: customRates,
      );
      expect(idrFromUsd, closeTo(80000.0, 0.001));

      // 3. GBP ke EUR: £ 17 -> EUR 20
      // 17 * 20.000 IDR = 340.000 IDR / 17.000 EUR = 20.0 EUR
      final eurFromGbp = CurrencyUtils.convert(
        amount: 17.0,
        fromCurrency: 'GBP',
        toCurrency: 'EUR',
        ratesToIdr: customRates,
      );
      expect(eurFromGbp, closeTo(20.0, 0.001));
    });

    test('Pemformatan Rupiah dan Valuta Asing menghasilkan teks rapi', () {
      expect(CurrencyUtils.formatIdr(50000), contains('50.000'));
      expect(CurrencyUtils.formatCurrency(15.5, 'USD'), contains('15.50'));
    });

    test('Konversi zona waktu akurat lintas WIB, WITA, WIT, dan London', () {
      // Waktu UTC: 2026-10-21 00:00:00 UTC
      final utcTime = DateTime.utc(2026, 10, 21, 0, 0, 0);

      // WIB adalah UTC+7 -> 07:00
      final wib = TimeZoneUtils.convertToZone(utcTime, 'WIB');
      expect(wib.hour, equals(7));

      // WITA adalah UTC+8 -> 08:00
      final wita = TimeZoneUtils.convertToZone(utcTime, 'WITA');
      expect(wita.hour, equals(8));

      // WIT adalah UTC+9 -> 09:00
      final wit = TimeZoneUtils.convertToZone(utcTime, 'WIT');
      expect(wit.hour, equals(9));

      // London pada tanggal 21 Oktober masih BST (British Summer Time, UTC+1) -> 01:00
      final london = TimeZoneUtils.convertToZone(utcTime, 'London');
      expect(london.hour, equals(1));
    });
  });
}
