import 'package:google_generative_ai/google_generative_ai.dart';

/// Layanan AI Pakar Fiqih Zakat dan Filantropi Islam (RF-008).
///
/// Menghubungkan ke Gemini AI jika `GEMINI_API_KEY` disediakan melalui
/// `--dart-define=GEMINI_API_KEY=...` atau `--dart-define-from-file=.env`.
/// Jika API key tidak ada atau perangkat sedang offline/kuota habis,
/// otomatis beralih ke basis pengetahuan Fiqih Zakat kontekstual cerdas.
class GeminiAiService {
  GeminiAiService._();
  static final GeminiAiService instance = GeminiAiService._();

  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  GenerativeModel? _model;

  GenerativeModel? _getModel() {
    if (_apiKey.isEmpty) return null;
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.95,
      ),
      systemInstruction: Content.system('''
Anda adalah Pakar Fiqih Zakat dan Filantropi Islam yang cerdas, ramah, dan teliti (mengacu pada standar BAZNAS, fatwa MUI, dan jumhur ulama).

ATURAN PEMAHAMAN KONTEKS (PENTING):
1. Pahami NIAT dan KONTEKS di balik pertanyaan pengguna, meskipun pengguna TIDAK menyebutkan kata "zakat" secara langsung.
2. Pertanyaan yang membahas tentang:
   - Kepemilikan harta (emas, perak, tabungan, deposito, giro, gaji/penghasilan, bonus, tunjangan, hasil panen/pertanian, ternak, saham, reksadana, perdagangan/bisnis, barang temuan/rikaz, kripto).
   - Perhitungan kewajiban harta, batas minimal harta (nisab setara 85g emas), masa kepemilikan (haul 1 tahun hijriyah), atau persentase potongan (2,5%, 5%, 10%, 20%).
   - Penerima bantuan (mustahik / 8 asnaf QS. At-Taubah: 60), pemberi (muzakki), lembaga amil (BAZNAS/LAZ).
   - Perbandingan atau kaitan zakat dengan pajak (UU No. 23 Tahun 2011 sebagai pengurang Penghasilan Kena Pajak / PKP), infaq, sedekah, wakaf, dan fidyah.
   - Studi kasus kehidupan sehari-hari terkait keraguan membersihkan dan menyucikan harta.
   SEMUA ITU ADALAH TOPIK YANG VALID dan WAJIB Anda jawab dengan lengkap, jelas, dan solutif dari sudut pandang fiqih zakat.

3. CARA MENJAWAB:
   - Jika pengguna memberikan studi kasus (misalnya menyebutkan jumlah gaji, utang, saldo tabungan, atau jumlah emas tanpa menyebut kata zakat), langsung analisis apakah harta tersebut sudah mencapai nisab dan haul zakat, lalu berikan perhitungannya secara matematis dan mudah dipahami.
   - Asumsi harga emas terkini: gunakan acuan standar BAZNAS terbaru (± Rp 1.300.000 / gram; nisab tahunan 85g = Rp 110.500.000; nisab bulanan = ± Rp 9.200.000/bulan).
   - Gunakan bahasa Indonesia yang luwes, santun, hangat, dan mudah dipahami masyarakat umum. Sertakan dasar hukum (Al-Qur'an, Hadits, atau ketentuan BAZNAS/MUI) jika relevan.
   - Format jawaban dengan struktur rapi menggunakan bullet points dan penekanan cetak tebal (bold) untuk angka atau kesimpulan pokok.

4. BATASAN PENOLAKAN (GUARDRAIL):
   - HANYA tolak pertanyaan jika 100% tidak memiliki kaitan langsung maupun tidak langsung dengan harta, keuangan, zakat, sedekah, atau filantropi Islam (contoh: bertanya resep masakan, tutorial coding/pemrograman, politik praktis, cuaca, olahraga, atau gosip).
   - Saat menolak, sampaikan dengan sopan bahwa Anda adalah asisten khusus konsultasi Zakat dan Filantropi Islam KitaBantu, lalu berikan contoh konkret bagaimana pengguna bisa mengaitkan topik keuangan/hartanya dengan zakat (misal: "Anda dapat menanyakan perhitungan zakat dari penghasilan, nisab tabungan atau emas, kaitan pajak dan zakat, atau ketentuan penerima zakat").
'''),
    );
    return _model;
  }

  /// Menjawab pertanyaan seputar zakat & donasi dengan riwayat obrolan (multi-turn context).
  Future<String> askZakatQuestion(
    String question, {
    List<Map<String, String>>? history,
  }) async {
    final model = _getModel();
    if (model != null) {
      try {
        List<Content>? historyContents;
        if (history != null && history.isNotEmpty) {
          historyContents = [];
          for (final msg in history) {
            final role = msg['role'];
            final text = msg['text'] ?? '';
            if (text.trim().isNotEmpty) {
              if (role == 'user') {
                historyContents.add(Content('user', [TextPart(text)]));
              } else if (role == 'ai') {
                historyContents.add(Content('model', [TextPart(text)]));
              }
            }
          }
        }

        final chat = model.startChat(history: historyContents);
        final response = await chat.sendMessage(Content.text(question));
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (_) {
        // Fallback otomatis ke basis pengetahuan bawaan jika ada kendala jaringan/kuota
      }
    }

    return _generateKnowledgeBaseAnswer(question);
  }

  /// Basis pengetahuan fiqih lokal kontekstual cerdas saat offline / tanpa API key.
  String _generateKnowledgeBaseAnswer(String q) {
    final query = q.toLowerCase().trim();

    // ─────────────────────────────────────────────────────────────────────────
    // 1. GUARDRAIL PENOLAKAN TOPIK DI LUAR HARTA / ZAKAT / FILANTROPI
    // ─────────────────────────────────────────────────────────────────────────
    final isUnrelated = (query.contains('resep') ||
            query.contains('masak') ||
            query.contains('bumbu') ||
            query.contains('coding') ||
            query.contains('flutter') ||
            query.contains('programming') ||
            query.contains('python') ||
            query.contains('javascript') ||
            query.contains('presiden') ||
            query.contains('pemilu') ||
            query.contains('partai politik') ||
            query.contains('cuaca hari ini') ||
            query.contains('skor bola') ||
            query.contains('game')) &&
        !query.contains('zakat') &&
        !query.contains('uang') &&
        !query.contains('harta') &&
        !query.contains('gaji') &&
        !query.contains('sedekah');

    if (isUnrelated) {
      return 'Mohon maaf, saya adalah **Asisten Khusus Konsultasi Zakat dan Filantropi Islam KitaBantu**.\n\n'
          'Pertanyaan Anda berada di luar bidang keahlian saya mengenai fiqih harta dan filantropi Islam.\n\n'
          '💡 **Anda dapat berkonsultasi mengenai topik seperti:**\n'
          '• Analisis kewajiban zakat dari gaji, honor, atau penghasilan bulanan\n'
          '• Perhitungan batas kepemilikan (nisab) tabungan, emas, dan deposito\n'
          '• Zakat atas investasi saham, reksadana, atau bisnis perdagangan\n'
          '• Kaitan antara pembayaran zakat dengan pemotongan pajak (PKP)\n'
          '• Kriteria 8 golongan yang berhak menerima bantuan (asnaf)\n\n'
          '_Silakan sampaikan pertanyaan atau studi kasus keuangan Anda!_';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. STUDI KASUS GAJI / PENGHASILAN / PROFESI (Termasuk tanpa kata "zakat")
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('gaji') ||
        query.contains('penghasilan') ||
        query.contains('pendapatan') ||
        query.contains('upah') ||
        query.contains('honor') ||
        query.contains('bonus') ||
        query.contains('karyawan') ||
        query.contains('freelance') ||
        query.contains('profesi') ||
        query.contains('dapat uang') ||
        query.contains('tiap bulan') ||
        query.contains('per bulan')) {
      return '💼 **Analisis Kewajiban Zakat Penghasilan / Profesi:**\n\n'
          'Berdasarkan **Fatwa MUI No. 3 Tahun 2003** dan ketentuan **BAZNAS**, setiap penghasilan dari pekerjaan halal wajib dikeluarkan zakatnya jika telah mencapai nisab.\n\n'
          '📌 **Ketentuan & Batasan:**\n'
          '• **Nisab Bulanan:** Setara 85 gram emas per tahun dibagi 12 bulan = **± Rp 9.200.000 / bulan** (dengan estimasi emas Rp 1.300.000/g).\n'
          '• **Kadar Zakat:** **2.5%** dari penghasilan bersih.\n'
          '• **Dasar Perhitungan:** `(Penghasilan Bruto - Pengeluaran Pokok Mendesak/Cicilan Utang) × 2.5%`\n\n'
          '📊 **Simulasi Studi Kasus:**\n'
          '• *Jika penghasilan bersih Rp 10.000.000/bulan:* Karena >= Rp 9.200.000, maka **wajib zakat** sebesar `Rp 10.000.000 × 2.5% = Rp 250.000 / bulan`.\n'
          '• *Jika penghasilan bersih Rp 15.000.000/bulan:* Zakatnya adalah `Rp 15.000.000 × 2.5% = Rp 375.000 / bulan`.\n'
          '• *Jika penghasilan bersih di bawah Rp 9.200.000/bulan:* Anda **tidak wajib zakat**, namun sangat dianjurkan menyisihkan infak atau sedekah sukarela.\n\n'
          '📖 *Dasar Hukum: QS. Al-Baqarah ayat 267 ("Nafkahkanlah sebagian dari hasil usahamu yang baik-baik").*';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. EMAS, PERAK, PERHIASAN, & LOGAM MULIA
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('emas') ||
        query.contains('perak') ||
        query.contains('antam') ||
        query.contains('gram') ||
        query.contains('perhiasan')) {
      return '✨ **Analisis Fiqih Kepemilikan Emas & Logam Mulia:**\n\n'
          'Emas merupakan standar utama ukuran harta dalam syariat Islam (*asl al-amwal*).\n\n'
          '📌 **Ketentuan Nisab & Haul:**\n'
          '• **Nisab Emas:** **85 gram emas murni**.\n'
          '• **Nisab Perak:** **595 gram perak murni**.\n'
          '• **Syarat Haul:** Telah dimiliki dan tersimpan genap selama **1 tahun hijriyah**.\n'
          '• **Kadar Zakat:** **2.5%** dari total berat/nilai emas.\n\n'
          '🔍 **Ketentuan Khusus:**\n'
          '1. **Emas Batangan / Investasi:** Wajib dizakati penuh jika totalnya >= 85 gram dan mencapai haul 1 tahun.\n'
          '   *Contoh:* Punya 100 gram emas disimpan 1 tahun → Zakat = `100 gram × 2.5% = 2.5 gram emas` (atau senilai uang Rp 3.250.000 jika harga emas Rp 1.300.000/g).\n'
          '2. **Perhiasan yang Dipakai Wajar:** Menurut jumhur ulama (termasuk Mazhab Syafi\'i), perhiasan wanita yang dipakai sehari-hari dalam batas wajar **tidak dikenai zakat**. Namun jika berlebihan atau disimpan sebagai tabungan, maka wajib dizakati saat mencapai nisab 85g.\n\n'
          '📖 *Dasar Hukum: HR. Abu Dawud No. 1573 dan Fatwa BAZNAS No. 2 Tahun 2024.*';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. TABUNGAN, DEPOSITO, GIRO, SALDO BANK, & BUNGA RIBA
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('tabungan') ||
        query.contains('deposito') ||
        query.contains('giro') ||
        query.contains('saldo') ||
        query.contains('simpanan') ||
        query.contains('rekening') ||
        query.contains('bunga bank') ||
        query.contains('riba')) {
      return '💰 **Analisis Zakat Tabungan, Deposito, & Pembersihan Bunga:**\n\n'
          'Uang kas, saldo rekening tabungan, dan deposito memiliki fungsi yang sama dengan emas/perak sebagai alat tukar penimbun kekayaan (Zakat Maal Simpanan).\n\n'
          '📌 **Kriteria Kewajiban:**\n'
          '• **Batas Minimal (Nisab):** Setara harga 85 gram emas murni (± **Rp 110.500.000**).\n'
          '• **Syarat Waktu (Haul):** Saldo mengendap selama 1 tahun (dihitung dari saldo terendah selama 1 tahun atau saldo akhir haul).\n'
          '• **Besaran Zakat:** **2.5%** dari saldo pokok simpanan.\n\n'
          '⚠️ **Perlakuan Bunga Bank Konvensional:**\n'
          '• Bunga bank berstatus harta riba yang **tidak boleh dihitung sebagai harta zakat** dan tidak boleh dinikmati pribadi.\n'
          '• Bunga bank wajib dibersihkan 100% dan disalurkan secara terpisah untuk fasilitas sosial kemanusiaan umum (seperti perbaikan jalan, jembatan, MCK umum).\n\n'
          '📖 *Dasar Hukum: Fatwa MUI tentang Zakat Harta Simpanan dan Bunga Perbankan.*';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. HUBUNGAN ZAKAT DENGAN PAJAK & BUKTI POTONG (PKP)
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('pajak') ||
        query.contains('tax') ||
        query.contains('npwp') ||
        query.contains('spt') ||
        query.contains('pkp')) {
      return '🏛️ **Kaitan Hukum Zakat dan Pajak di Indonesia:**\n\n'
          'Banyak masyarakat bertanya: *"Jika sudah taat membayar pajak ke negara, apakah masih berkewajiban membayar zakat?"*\n\n'
          '⚖️ **Tinjauan Fiqih & Regulasi:**\n'
          '1. **Kewajiban Berbeda:** Zakat adalah kewajiban **keagamaan (*ubudiyah*)** kepada Allah SWT untuk 8 asnaf, sedangkan pajak adalah kewajiban **kewarganegaraan (*muwathanah*)** untuk pembiayaan fasilitas negara. Keduanya tidak saling menggugurkan.\n'
          '2. **Zakat Mengurangi Penghasilan Kena Pajak (PKP):**\n'
          '   Berdasarkan **UU No. 23 Tahun 2011 Pasal 22** dan **UU Pajak Penghasilan (PPh) No. 36 Tahun 2008 Pasal 9 ayat 1**:\n'
          '   _Zakat yang dibayarkan melalui Badan Amil Zakat resmi (BAZNAS / LAZ berizin) dapat dijadikan sebagai faktor pengurang Penghasilan Kena Pajak (PKP) dalam pelaporan SPT tahunan._\n\n'
          '💡 *Saran Praktis:* Tunaikan zakat melalui BAZNAS atau LAZ resmi agar memperoleh Bukti Setor Zakat (BSZ) resmi yang diakui oleh Ditjen Pajak saat lapor SPT.';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 6. SAHAM, REKSADANA, TRADING, KRIPTO, & INVESTASI
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('saham') ||
        query.contains('reksadana') ||
        query.contains('reksa dana') ||
        query.contains('kripto') ||
        query.contains('crypto') ||
        query.contains('bitcoin') ||
        query.contains('investasi') ||
        query.contains('dividen') ||
        query.contains('trading')) {
      return '📈 **Analisis Fiqih Zakat Portofolio Investasi & Kripto:**\n\n'
          'Investasi pada instrumen keuangan modern wajib dizakati berlandaskan **Fatwa DSN-MUI No. 138/DSN-MUI/IX/2020**.\n\n'
          '📌 **1. Saham untuk Jual-Beli Jangka Pendek (Trading / Capital Gain):**\n'
          '• Diperlakukan seperti **Zakat Perdagangan (*Urudh at-Tijarah*)**.\n'
          '• Rumus: `(Nilai Pasar Portofolio Akhir Tahun + Saldo Kas RDN - Utang Margin) × 2.5%`.\n'
          '• Syarat: Total aset mencapai nisab 85g emas (± Rp 110.5jt) dan berjalan 1 tahun.\n\n'
          '📌 **2. Saham Jangka Panjang (Memburu Dividen):**\n'
          '• Zakat dikeluarkan sebesar **2.5%** dari dividen bersih yang diterima.\n\n'
          '📌 **3. Aset Kripto / Digital Currency:**\n'
          '• Jika disimpan sebagai komoditas investasi/perdagangan yang halal, zakatnya setara zakat perniagaan sebesar **2.5%** saat mencapai nisab 85 gram emas dan haul 1 tahun.\n\n'
          '⚠️ *Pastikan aset saham atau token yang dimiliki bergerak di sektor yang halal dan tidak melanggar prinsip syariah.*';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 7. PERNIAGAAN / DAGANG / BISNIS / TOKO / USAHA
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('dagang') ||
        query.contains('perniagaan') ||
        query.contains('bisnis') ||
        query.contains('usaha') ||
        query.contains('toko') ||
        query.contains('jualan') ||
        query.contains('omset') ||
        query.contains('omzet') ||
        query.contains('modal kerja')) {
      return '🏪 **Panduan Fiqih Zakat Perniagaan & Bisnis:**\n\n'
          'Zakat perniagaan wajib atas segala harta yang diperjualbelikan demi mencari keuntungan.\n\n'
          '📌 **Syarat Wajib:**\n'
          '• Dijalankan selama 1 tahun buku (haul 1 tahun).\n'
          '• Nilai aset lancar mencapai nisab 85 gram emas (± **Rp 110.500.000**).\n'
          '• Kadar zakat: **2.5%**.\n\n'
          '🧮 **Rumus Standar BAZNAS:**\n'
          '`Zakat = [(Uang Kas/Bank + Stok Barang Dagangan + Piutang Lancar) - Utang Jatuh Tempo] × 2.5%`\n\n'
          '💡 *Aset tetap seperti bangunan toko, etalase, rak, dan kendaraan operasional TIDAK dihitung dalam nilai zakat perniagaan.*';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 8. HASIL PERTANIAN, PERKEBUNAN, & PANEN
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('tani') ||
        query.contains('pertanian') ||
        query.contains('panen') ||
        query.contains('sawah') ||
        query.contains('padi') ||
        query.contains('beras') ||
        query.contains('jagung') ||
        query.contains('hasil bumi')) {
      return '🌾 **Analisis Zakat Pertanian & Hasil Bumi:**\n\n'
          'Zakat tanaman pangan pokok dan buah-buahan wajib dikeluarkan **langsung setiap kali panen tiba** tanpa menunggu haul 1 tahun (QS. Al-An\'am: 141).\n\n'
          '📌 **Ketentuan Nisab:**\n'
          '• Nisabnya adalah 5 wasaq = setara **± 653 kg gabah kering giling** atau **± 520 kg beras bersih**.\n\n'
          '💧 **Persentase Potongan Zakat:**\n'
          '• **10%:** Jika diairi secara alami (air hujan atau aliran sungai tanpa biaya irigasi).\n'
          '• **5%:** Jika diairi dengan biaya operasional (pompa air listrik/diesel, membeli air, pupuk mahal).\n'
          '• **7.5%:** Jika pengairannya kombinasi berimbang antara alami dan berbiaya.\n\n'
          '⚠️ *Zakat dihitung dari hasil kotor panen sebelum dikurangi biaya operasional panen menurut jumhur ulama.*';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 9. HEWAN TERNAK (AN'AM)
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('ternak') ||
        query.contains('kambing') ||
        query.contains('domba') ||
        query.contains('sapi') ||
        query.contains('kerbau') ||
        query.contains('unta')) {
      return '🐑 **Analisis Zakat Hewan Ternak (*An\'am*):**\n\n'
          'Hewan ternak yang digembalakan di padang rumput bebas (*sa\'imah*) dan dimiliki selama 1 tahun (haul) wajib dizakati dengan rincian nisab:\n\n'
          '• **Kambing / Domba:**\n'
          '  - 40 - 120 ekor = **1 ekor kambing**\n'
          '  - 121 - 200 ekor = **2 ekor kambing**\n'
          '  - 201 - 399 ekor = **3 ekor kambing**\n'
          '• **Sapi / Kerbau:**\n'
          '  - 30 - 39 ekor = **1 ekor sapi umur 1 tahun (Tabi\')**\n'
          '  - 40 - 59 ekor = **1 ekor sapi umur 2 tahun (Musinnah)**\n\n'
          '💡 *Catatan Modern:* Untuk peternakan komersial kandang dengan pakan beli pabrikan (ayam broiler, puyuh, bebek), perhitungannya mengikuti **Zakat Perniagaan** (2.5% dari aset lancar & laba).';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 10. BARANG TEMUAN, HARTA KARUN, BARANG TAMBANG (RIKAZ & MA'DIN)
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('temuan') ||
        query.contains('karun') ||
        query.contains('rikaz') ||
        query.contains('tambang') ||
        query.contains('terpendam') ||
        query.contains('nemu')) {
      return '🏺 **Fiqih Barang Temuan (Rikaz) & Barang Tambang (Ma\'din):**\n\n'
          '• **Harta Karun Terpendam (Rikaz):**\n'
          '  Barang berharga peninggalan masa lalu yang ditemukan tanpa modal pencarian berat dikenai zakat sebesar **20% (seperlima)**.\n'
          '  *Kelebihan Rikaz:* **Tidak ada syarat nisab dan tidak ada syarat haul 1 tahun** — zakat wajib dikeluarkan saat barang tersebut ditemukan.\n'
          '• **Hasil Tambang (Ma\'din):**\n'
          '  Emas/perak atau mineral berharga yang dieksploitasi dikenai zakat **2.5%** seketika saat diolah dan mencapai nisab 85 gram emas.\n\n'
          '📖 *Dasar Hukum: HR. Bukhari No. 1499 ("Dan pada rikaz itu kewajiban zakatnya adalah seperlima/20%").*';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 11. MUSTAHIK (8 ASNAF), HUKUM KELUARGA/KERABAT
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('asnaf') ||
        query.contains('mustahik') ||
        query.contains('penerima') ||
        query.contains('berhak') ||
        query.contains('orang tua') ||
        query.contains('saudara') ||
        query.contains('tetangga') ||
        query.contains('anak yatim') ||
        query.contains('bolehkah zakat')) {
      return '👥 **8 Asnaf Penerima Zakat & Hukum Menyalurkan ke Kerabat:**\n\n'
          'Berdasarkan **QS. At-Taubah ayat 60**, zakat HANYA boleh disalurkan kepada 8 asnaf:\n'
          '1. **Fakir:** Tidak punya harta dan mata pencaharian layak.\n'
          '2. **Miskin:** Memiliki penghasilan tapi tidak cukup untuk kebutuhan dasar.\n'
          '3. **Amil:** Pengelola resmi zakat.\n'
          '4. **Mualaf:** Orang yang baru memeluk Islam atau dilembutkan hatinya.\n'
          '5. **Riqab:** Upaya pembebasan dari jeratan perbudakan/eksploitasi.\n'
          '6. **Gharimin:** Orang yang terlilit hutang demi kebutuhan hidup halal.\n'
          '7. **Fisabilillah:** Aktivitas penegakan dakwah, pendidikan Islam, dan kemaslahatan umat.\n'
          '8. **Ibnu Sabil:** Musafir yang kehabisan bekal dalam ketaatan.\n\n'
          '❓ **Bolehkah Menyalurkan ke Kerabat Sendiri?**\n'
          '• **TIDAK BOLEH** diberikan kepada orang yang berada di bawah tanggungan nafkah wajib Anda: orang tua kandung, anak kandung, dan istri.\n'
          '• **SANGAT DIANJURKAN** diberikan kepada kerabat yang bukan tanggungan nafkah (saudara kandung, paman, bibi, keponakan, sepupu) jika mereka fakir/miskin. Anda memperoleh **dua pahala**: pahala zakat dan pahala silaturahim (HR. Tirmidzi No. 658).\n'
          '• Anak yatim boleh menerima zakat **jika** ia tergolong fakir atau miskin.';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 12. PERBEDAAN ZAKAT, INFAK, SEDEKAH, WAKAF, & FIDYAH
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('sedekah') ||
        query.contains('infak') ||
        query.contains('infaq') ||
        query.contains('wakaf') ||
        query.contains('fidyah') ||
        query.contains('beda') ||
        query.contains('perbedaan')) {
      return '⚖️ **Perbandingan Zakat, Infak, Sedekah, Wakaf, & Fidyah:**\n\n'
          '• **Zakat:** Hukumnya **Wajib / Fardhu Ain**. Memiliki nisab (85g emas), haul (1 tahun), tarif tertentu (2.5%), dan target 8 asnaf.\n'
          '• **Infak:** Mengeluarkan sebagian harta untuk kemaslahatan umum tanpa batasan nisab, haul, maupun persentase (sunnah/sukarela).\n'
          '• **Sedekah:** Segala kebajikan mencakup materi maupun non-materi (senyum, ilmu, tenaga, menolong orang lain).\n'
          '• **Wakaf:** Menyedekahkan aset abadi/produktif (tanah, gedung, wakaf uang) untuk dimanfaatkan maslahatnya secara kekal bagi umat.\n'
          '• **Fidyah:** Kompensasi pengganti puasa bagi yang tidak mampu berpuasa permanen (lansia renta, sakit menahun) dengan memberi makan 1 orang miskin per hari puasa (± **Rp 45.000 – Rp 60.000 / hari**).\n\n'
          '💡 *Aplikasi KitaBantu mendukung simulasi zakat terhitung dan donasi filantropi sosial.*';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 13. ZAKAT FITRAH & RAMADHAN
    // ─────────────────────────────────────────────────────────────────────────
    if (query.contains('fitrah') ||
        query.contains('idul fitri') ||
        query.contains('lebaran') ||
        query.contains('jiwa')) {
      return '🌾 **Ketentuan Zakat Fitrah (Jiwa):**\n\n'
          '• **Subjek:** Wajib atas setiap jiwa muslim yang hidup di penghujung bulan Ramadhan dan memiliki kelebihan makanan pokok di malam Idul Fitri.\n'
          '• **Kadar:** **2.5 kg atau 3.5 liter beras** per orang.\n'
          '• **Konversi Uang:** Disesuaikan dengan SK BAZNAS daerah masing-masing (umumnya **Rp 45.000 – Rp 55.000 per jiwa**).\n'
          '• **Waktu Batas:** Wajib ditunaikan sebelum pelaksanaan Shalat Idul Fitri agar sah berstatus zakat fitrah.\n'
          '• **Penerima:** Diutamakan untuk fakir dan miskin agar kebutuhan pangannya tercukupi di hari raya.';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 14. DEFAULT FALLBACK KOMPREHENSIF (Jika kata tidak spesifik)
    // ─────────────────────────────────────────────────────────────────────────
    return 'Assalamu\'alaikum! Saya **Pakar Fiqih Zakat dan Filantropi Islam KitaBantu**.\n\n'
        'Saya siap membantu Anda memahami kewajiban dan tata cara pembersihan harta, antara lain:\n\n'
        '1. **Analisis Gaji & Profesi:** Hitung kewajiban 2.5% dari gaji, honor, atau penghasilan bulanan Anda.\n'
        '2. **Nisab & Haul Emas/Tabungan:** Batas minimal 85 gram emas (± Rp 110.5jt) dan kepemilikan 1 tahun.\n'
        '3. **Investasi & Bisnis:** Fiqih zakat saham, reksadana, kripto, dan modal kerja perdagangan.\n'
        '4. **Kaitan Pajak & Zakat:** Cara memanfaatkan zakat sebagai pengurang Penghasilan Kena Pajak (PKP).\n'
        '5. **Penyaluran:** Kriteria 8 asnaf dan hukum menyalurkan zakat ke saudara/kerabat.\n\n'
        '💡 *Silakan ketik pertanyaan, nominal pendapatan, atau studi kasus keuangan Anda langsung di bawah ini!*';
  }
}
