import 'package:flutter_test/flutter_test.dart';
import 'package:kitabantu/core/utils/zakat_calculator_utils.dart';

void main() {
  group('4. Unit Test: Perhitungan Nisab & Zakat 2.5% (RF-008 / Bab 12)', () {
    const testGoldPrice = 1000000.0; // Rp 1.000.000 / gram untuk kemudahan verifikasi

    test('Nisab tahunan (85g emas) dan bulanan (nisab tahunan / 12) dihitung dengan tepat', () {
      final yearlyNisab = ZakatCalculatorUtils.calculateYearlyNisab(testGoldPrice);
      // 85 * 1.000.000 = 85.000.000
      expect(yearlyNisab, equals(85000000.0));

      final monthlyNisab = ZakatCalculatorUtils.calculateMonthlyNisab(testGoldPrice);
      // 85.000.000 / 12 = 7.083.333.33
      expect(monthlyNisab, closeTo(7083333.33, 0.1));
    });

    test('Zakat Maal: wajib jika harta >= nisab, zakat = 2.5%', () {
      // Skenario 1: Harta Rp 100.000.000 (> Nisab Rp 85.000.000) -> Wajib
      final resultWajib = ZakatCalculatorUtils.calculateZakatMaal(
        totalWealth: 100000000.0,
        goldPrice: testGoldPrice,
      );

      expect(resultWajib.isWajib, isTrue);
      // 2.5% dari 100.000.000 = 2.500.000
      expect(resultWajib.zakatAmount, equals(2500000.0));

      // Skenario 2: Harta Rp 50.000.000 (< Nisab) -> Tidak wajib, zakat = 0
      final resultBelum = ZakatCalculatorUtils.calculateZakatMaal(
        totalWealth: 50000000.0,
        goldPrice: testGoldPrice,
      );

      expect(resultBelum.isWajib, isFalse);
      expect(resultBelum.zakatAmount, equals(0.0));
    });

    test('Zakat Penghasilan: wajib jika penghasilan bersih bulanan >= nisab bulanan', () {
      // Skenario 1: Gaji Rp 12.000.000, pengeluaran Rp 2.000.000 -> Bersih Rp 10.000.000 (> Nisab Rp 7.083.333) -> Wajib
      final resultWajib = ZakatCalculatorUtils.calculateZakatPenghasilan(
        monthlyIncome: 12000000.0,
        otherIncome: 0.0,
        monthlyExpense: 2000000.0,
        goldPrice: testGoldPrice,
      );

      expect(resultWajib.isWajib, isTrue);
      // 2.5% dari 10.000.000 = 250.000
      expect(resultWajib.zakatAmount, equals(250000.0));

      // Skenario 2: Gaji Rp 6.000.000 (< Nisab) -> Tidak Wajib
      final resultBelum = ZakatCalculatorUtils.calculateZakatPenghasilan(
        monthlyIncome: 6000000.0,
        goldPrice: testGoldPrice,
      );

      expect(resultBelum.isWajib, isFalse);
      expect(resultBelum.zakatAmount, equals(0.0));
    });
  });
}
