import 'package:google_generative_ai/google_generative_ai.dart';

/// Layanan AI Asisten Fiqih Zakat (RF-008).
///
/// Menghubungkan ke Gemini AI jika `GEMINI_API_KEY` disediakan melalui
/// `--dart-define=GEMINI_API_KEY=...` atau `--dart-define-from-file=.env`.
/// Jika API key tidak ada atau perangkat sedang offline,
/// otomatis beralih ke basis pengetahuan Fiqih Zakat bawaan yang cerdas.
class GeminiAiService {
  GeminiAiService._();
  static final GeminiAiService instance = GeminiAiService._();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  GenerativeModel? _model;

  GenerativeModel? _getModel() {
    if (_apiKey.isEmpty) return null;
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'Anda adalah "Asisten Zakat KitaBantu", seorang pakar fiqih zakat digital yang ramah, '
        'bijaksana, dan berlandaskan dalil Al-Qur\'an, Hadis, serta fatwa BAZNAS/MUI. '
        'Bantulah pengguna menghitung zakat (2.5%), menjelaskan nisab 85 gram emas, '
        'haul 1 tahun, serta 8 golongan penerima (asnaf). '
        'Selalu sertakan disclaimer santun bahwa jawaban ini bersifat edukasi dan konsultasi '
        'lebih lanjut dapat diajukan ke amil zakat terdekat.',
      ),
    );
    return _model;
  }

  /// Menjawab pertanyaan seputar zakat & donasi.
  Future<String> askZakatQuestion(String question) async {
    final model = _getModel();
    if (model != null) {
      try {
        final content = [Content.text(question)];
        final response = await model.generateContent(content);
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (_) {
        // Fallback ke basis pengetahuan bawaan jika ada kendala jaringan/kuota
      }
    }

    return _generateKnowledgeBaseAnswer(question);
  }

  /// Basis pengetahuan fiqih lokal saat offline / tanpa API key.
  String _generateKnowledgeBaseAnswer(String q) {
    final query = q.toLowerCase();

    if (query.contains('nisab') || query.contains('emas')) {
      return '📌 **Ketentuan Nisab Zakat (BAZNAS):**\n\n'
          '• **Zakat Maal (Harta/Emas):** Nisabnya setara **85 gram emas murni**. '
          'Jika harga emas saat ini Rp 1.300.000/gram, maka nisabnya adalah **Rp 110.500.000** '
          'dengan syarat kepemilikan telah mencapai 1 tahun (haul).\n'
          '• **Zakat Penghasilan/Profesi:** Nisab per bulannya setara 85 gram emas dibagi 12 bulan '
          '(± Rp 9.200.000/bulan).\n\n'
          '_Kadar zakat yang wajib dikeluarkan adalah **2.5%**._\n\n'
          '⚠️ *Catatan: Informasi ini bersifat panduan edukasi KitaBantu.*';
    }

    if (query.contains('asnaf') || query.contains('penerima') || query.contains('golongan')) {
      return '👥 **8 Golongan Penerima Zakat (QS. At-Taubah: 60):**\n\n'
          '1. **Fakir:** Tidak memiliki harta dan penghasilan cukup.\n'
          '2. **Miskin:** Memiliki penghasilan namun belum mencukupi kebutuhan pokok.\n'
          '3. **Amil:** Pengelola atau panitia penyalur zakat.\n'
          '4. **Mualaf:** Orang yang baru memeluk Islam atau dilembutkan hatinya.\n'
          '5. **Riqab:** Hamba sahaya / upaya pembebasan jeratan eksploitasi.\n'
          '6. **Gharim:** Orang yang terlilit hutang demi kebutuhan mendesak yang halal.\n'
          '7. **Fisabilillah:** Pejuang di jalan kebaikan dan kemaslahatan umat.\n'
          '8. **Ibnu Sabil:** Musafir yang kehabisan bekal dalam perjalanan ketaatan.\n\n'
          '⚠️ *Catatan: Informasi ini bersifat panduan edukasi KitaBantu.*';
    }

    if (query.contains('profesi') || query.contains('gaji') || query.contains('penghasilan')) {
      return '💼 **Panduan Zakat Penghasilan / Profesi:**\n\n'
          'Zakat profesi dihitung dari penghasilan bulanan bersih (gaji kotor dikurangi kebutuhan pokok mendesak).\n\n'
          '• **Rumus:** `Penghasilan Bersih x 2.5%`\n'
          '• **Syarat Wajib:** Penghasilan bersih per bulan mencapai batas nisab (± Rp 9.200.000).\n'
          '• Jika belum mencapai nisab, Anda tidak berkewajiban zakat, namun sangat dianjurkan bersedekah atau berinfak secara sukarela.\n\n'
          '⚠️ *Catatan: Informasi ini bersifat panduan edukasi KitaBantu.*';
    }

    if (query.contains('tabungan') || query.contains('deposito') || query.contains('maal')) {
      return '💰 **Panduan Zakat Tabungan & Deposito (Maal):**\n\n'
          'Tabungan, giro, atau deposito yang mengendap selama 1 tahun (haul) dan saldo terendahnya '
          'mencapai nilai 85 gram emas wajib dizakati sebesar **2.5%**.\n\n'
          '• Bunga bank konvensional (riba) tidak boleh dihitung sebagai harta zakat dan harus disalurkan untuk kepentingan sosial umum.\n\n'
          '⚠️ *Catatan: Informasi ini bersifat panduan edukasi KitaBantu.*';
    }

    return 'Salam hangat! Saya Asisten Zakat Digital KitaBantu.\n\n'
        'Anda dapat bertanya mengenai:\n'
        '• Perhitungan Nisab Emas & Zakat Maal (2.5%)\n'
        '• Cara menghitung Zakat Profesi / Gaji Bulanan\n'
        '• 8 Golongan Penerima Zakat (Asnaf)\n'
        '• Simulasi donasi dan transparansi ledger blockchain.\n\n'
        'Silakan masukkan pertanyaan spesifik Anda di kolom input di bawah ini!\n\n'
        '⚠️ *Catatan: Jawaban asisten ini ditujukan untuk kebutuhan edukasi digital.*';
  }
}
