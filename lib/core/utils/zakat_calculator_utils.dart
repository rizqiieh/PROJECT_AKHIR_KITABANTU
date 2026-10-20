/// Utilitas Kalkulator Zakat Fiqih (RF-008 & Bab 12 - Unit Test 4).
///
/// Mengikuti ketetapan BAZNAS:
/// - Kadar zakat Maal & Penghasilan: 2.5%
/// - Nisab Zakat Maal: setara 85 gram emas (haul 1 tahun)
/// - Nisab Zakat Penghasilan: setara 85 gram emas per tahun (atau dibagi 12 per bulan)
class ZakatCalculatorUtils {
  ZakatCalculatorUtils._();

  /// Default estimasi harga emas per gram (IDR).
  static const double defaultGoldPricePerGram = 1300000.0;

  /// Berat nisab standar emas dalam gram.
  static const double nisabGoldGrams = 85.0;

  /// Tarif zakat resmi (2.5%).
  static const double zakatRate = 0.025;

  /// Menghitung nilai nisab tahunan (85 gram * harga emas).
  static double calculateYearlyNisab([double goldPrice = defaultGoldPricePerGram]) {
    return nisabGoldGrams * goldPrice;
  }

  /// Menghitung nilai nisab bulanan (nisab tahunan / 12).
  static double calculateMonthlyNisab([double goldPrice = defaultGoldPricePerGram]) {
    return calculateYearlyNisab(goldPrice) / 12.0;
  }

  /// Menghitung Zakat Maal (Harta Simpanan: tabungan, emas, investasi setelah 1 tahun/haul).
  ///
  /// Syarat: [totalWealth] >= Nisab Tahunan.
  /// Jika wajib: Zakat = 2.5% * totalWealth.
  /// Jika belum wajib: Zakat = 0.
  static ZakatCalculationResult calculateZakatMaal({
    required double totalWealth,
    double goldPrice = defaultGoldPricePerGram,
  }) {
    final nisab = calculateYearlyNisab(goldPrice);
    final isWajib = totalWealth >= nisab;
    final zakatAmount = isWajib ? (totalWealth * zakatRate) : 0.0;

    return ZakatCalculationResult(
      zakatType: 'Maal',
      totalWealth: totalWealth,
      nisabThreshold: nisab,
      isWajib: isWajib,
      zakatAmount: zakatAmount,
      explanation: isWajib
          ? 'Harta Anda telah mencapai nisab (Rp ${nisab.toStringAsFixed(0)}). Wajib mengeluarkan zakat 2.5%.'
          : 'Harta Anda belum mencapai nisab (Rp ${nisab.toStringAsFixed(0)}). Tidak wajib zakat maal, disarankan infak/sedekah sukarela.',
    );
  }

  /// Menghitung Zakat Penghasilan / Profesi (per bulan).
  ///
  /// Bersih = (penghasilanBulanan + penghasilanLain) - pengeluaranPokok.
  /// Syarat: penghasilanBersih >= Nisab Bulanan.
  /// Jika wajib: Zakat = 2.5% * penghasilanBersih.
  /// Jika belum: Zakat = 0.
  static ZakatCalculationResult calculateZakatPenghasilan({
    required double monthlyIncome,
    double otherIncome = 0.0,
    double monthlyExpense = 0.0,
    double goldPrice = defaultGoldPricePerGram,
  }) {
    final netIncome = (monthlyIncome + otherIncome) - monthlyExpense;
    final validIncome = netIncome > 0 ? netIncome : 0.0;
    final nisab = calculateMonthlyNisab(goldPrice);
    final isWajib = validIncome >= nisab;
    final zakatAmount = isWajib ? (validIncome * zakatRate) : 0.0;

    return ZakatCalculationResult(
      zakatType: 'Penghasilan',
      totalWealth: validIncome,
      nisabThreshold: nisab,
      isWajib: isWajib,
      zakatAmount: zakatAmount,
      explanation: isWajib
          ? 'Penghasilan bersih Anda mencapai nisab bulanan (Rp ${nisab.toStringAsFixed(0)}). Wajib zakat profesi 2.5%.'
          : 'Penghasilan bersih Anda belum mencapai nisab bulanan (Rp ${nisab.toStringAsFixed(0)}). Tidak wajib zakat, disarankan sedekah.',
    );
  }
}

/// Hasil perhitungan zakat.
class ZakatCalculationResult {
  final String zakatType;
  final double totalWealth;
  final double nisabThreshold;
  final bool isWajib;
  final double zakatAmount;
  final String explanation;

  const ZakatCalculationResult({
    required this.zakatType,
    required this.totalWealth,
    required this.nisabThreshold,
    required this.isWajib,
    required this.zakatAmount,
    required this.explanation,
  });
}
