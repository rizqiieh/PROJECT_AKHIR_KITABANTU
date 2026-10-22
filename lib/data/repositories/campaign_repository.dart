import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/models/campaign_model.dart';
import 'package:kitabantu/data/models/ledger_model.dart';
import 'package:kitabantu/data/remote/supabase_service.dart';
import 'package:kitabantu/core/utils/ledger_utils.dart';

/// Repositori data kampanye donasi KitaBantu (RF-004, RF-005, RF-007).
///
/// Mengintegrasikan Database Online (Supabase) dan Database Lokal (SQLite)
/// dengan sistem sinkronisasi serta fallback offline otomatis.
class CampaignRepository {
  CampaignRepository._();
  static final CampaignRepository instance = CampaignRepository._();

  final _db = DatabaseHelper.instance;
  final _supabase = SupabaseService.instance;

  /// Daftar kampanye contoh (12 titik nyata di Yogyakarta & sekitarnya sesuai Bab 11).
  static const List<CampaignModel> _initialCampaigns = [
    CampaignModel(
      id: 'cmp-001',
      title: 'Santunan Pendidikan & Pangan Panti Asuhan Kotagede',
      description:
          'Membantu pemenuhan nutrisi harian dan perlengkapan sekolah bagi 45 anak yatim dan dhuafa binaan di kawasan Kotagede, Yogyakarta.',
      category: 'Panti Asuhan',
      targetAmount: 25000000.0,
      collectedAmount: 18500000.0,
      latitude: -7.8286,
      longitude: 110.3995,
      locationLabel: 'Kotagede, Kota Yogyakarta',
      endsAt: '2026-12-31T23:59:59Z',
      createdAt: '2026-09-01T08:00:00Z',
    ),
    CampaignModel(
      id: 'cmp-002',
      title: 'Bantuan Logistik Darurat Warga Lereng Merapi',
      description:
          'Pengadaan masker medis, air bersih siap minum, dan paket sembako untuk posko pengungsian tanggap darurat erupsi Merapi.',
      category: 'Bencana',
      targetAmount: 50000000.0,
      collectedAmount: 34200000.0,
      latitude: -7.5956,
      longitude: 110.4283,
      locationLabel: 'Cangkringan, Sleman, DIY',
      endsAt: '2026-11-15T23:59:59Z',
      createdAt: '2026-10-01T10:00:00Z',
    ),
    CampaignModel(
      id: 'cmp-003',
      title: 'Renovasi Asrama Panti Asuhan Rekso Putro',
      description:
          'Perbaikan atap bocor dan fasilitas MCK layak bagi puluhan anak asuh di asrama putra Yogyakarta.',
      category: 'Panti Asuhan',
      targetAmount: 40000000.0,
      collectedAmount: 21000000.0,
      latitude: -7.7956,
      longitude: 110.3695,
      locationLabel: 'Gondomanan, Kota Yogyakarta',
      endsAt: '2026-12-20T23:59:59Z',
      createdAt: '2026-09-10T11:00:00Z',
    ),
    CampaignModel(
      id: 'cmp-004',
      title: 'Beasiswa Santri Yatim Penghafal Al-Qur\'an Krapyak',
      description:
          'Dukungan biaya kitab, seragam, dan akomodasi belajar santri dhuafa di pesantren tahfidz Krapyak Sewon.',
      category: 'Pendidikan',
      targetAmount: 30000000.0,
      collectedAmount: 27500000.0,
      latitude: -7.8272,
      longitude: 110.3614,
      locationLabel: 'Krapyak, Sewon, Bantul',
      endsAt: '2026-12-10T23:59:59Z',
      createdAt: '2026-09-15T09:00:00Z',
    ),
    CampaignModel(
      id: 'cmp-005',
      title: 'Bantuan Pengobatan Anak Kurang Gizi & Stunting Kulon Progo',
      description:
          'Pemeriksaan rutin, suplemen vitamin, dan susu tinggi kalori untuk balita berisiko stunting di perbukitan Menoreh.',
      category: 'Kesehatan',
      targetAmount: 20000000.0,
      collectedAmount: 8400000.0,
      latitude: -7.7471,
      longitude: 110.1554,
      locationLabel: 'Girimulyo, Kulon Progo',
      endsAt: '2026-11-30T23:59:59Z',
      createdAt: '2026-10-05T07:30:00Z',
    ),
    CampaignModel(
      id: 'cmp-006',
      title: 'Tanggap Banjir Bandang & Longsor Imogiri',
      description:
          'Bantuan pembersihan material lumpur, obat-obatan gatal, serta kasur lipat bagi keluarga terdampak tanah longsor.',
      category: 'Bencana',
      targetAmount: 35000000.0,
      collectedAmount: 19800000.0,
      latitude: -7.9258,
      longitude: 110.3951,
      locationLabel: 'Imogiri, Bantul, DIY',
      endsAt: '2026-11-25T23:59:59Z',
      createdAt: '2026-10-08T13:00:00Z',
    ),
    CampaignModel(
      id: 'cmp-007',
      title: 'Pengadaan Ambulans Gratis Dhuafa Gunungkidul',
      description:
          'Pengadaan mobil layanan medis antar-jemput pasien kritis tidak mampu di pelosok Gunungkidul menuju RSUD Wonosari.',
      category: 'Kesehatan',
      targetAmount: 120000000.0,
      collectedAmount: 92000000.0,
      latitude: -7.9625,
      longitude: 110.6012,
      locationLabel: 'Wonosari, Gunungkidul',
      endsAt: '2027-01-31T23:59:59Z',
      createdAt: '2026-08-01T08:00:00Z',
    ),
    CampaignModel(
      id: 'cmp-008',
      title: 'Panti Asuhan Sinar Melati Kaliurang',
      description:
          'Pemberdayaan keterampilan kewirausahaan, komputer, dan biaya SPP bagi 30 anak asuh binaan mandiri.',
      category: 'Panti Asuhan',
      targetAmount: 25000000.0,
      collectedAmount: 14500000.0,
      latitude: -7.6978,
      longitude: 110.4142,
      locationLabel: 'Pakem, Sleman, DIY',
      endsAt: '2026-12-15T23:59:59Z',
      createdAt: '2026-09-20T14:00:00Z',
    ),
  ];

  final List<CampaignModel> _campaigns = [
    ..._initialCampaigns,
  ];

  /// Mengambil semua kampanye dengan filter kategori dan pencarian kata kunci.
  /// Jika Supabase online aktif, menyelaraskan data kampanye dari server.
  Future<List<CampaignModel>> getCampaigns({
    String? category,
    String? searchQuery,
  }) async {
    if (_supabase.isAvailable) {
      // 1. Coba ambil data dari Supabase
      var onlineCampaigns = await _supabase.fetchCampaigns();

      // 2. Jika Supabase masih kosong, unggah data awal secara otomatis
      if (onlineCampaigns.isEmpty) {
        await _supabase.seedInitialCampaigns(_initialCampaigns);
        onlineCampaigns = await _supabase.fetchCampaigns();
      }

      // 3. Sinkronkan ke daftar memori lokal
      if (onlineCampaigns.isNotEmpty) {
        for (var oc in onlineCampaigns) {
          final idx = _campaigns.indexWhere((c) => c.id == oc.id);
          if (idx != -1) {
            _campaigns[idx] = oc;
          } else {
            _campaigns.add(oc);
          }
        }
      }
    }

    return _campaigns.where((c) {
      final matchCategory =
          category == null || category == 'Semua' || c.category == category;
      final matchQuery = searchQuery == null ||
          searchQuery.trim().isEmpty ||
          c.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.locationLabel.toLowerCase().contains(searchQuery.toLowerCase());
      return matchCategory && matchQuery;
    }).toList();
  }
  /// Mengambil satu kampanye berdasarkan ID.
  Future<CampaignModel?> getCampaignById(String id) async {
    try {
      return _campaigns.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Simulasi Donasi Baru & Otomatis Pencatatan ke Rantai Hash Ledger (RF-007).
  ///
  /// Mencatat transaksi ke:
  /// 1. Memori Kampanye (update nominal terkumpul)
  /// 2. Database Online Supabase (`donations` & `ledger_entries`)
  /// 3. Database Lokal SQLite (`ledger_entries`)
  Future<LedgerModel> recordDonationAndCreateBlock({
    required String campaignId,
    required String donorName,
    required double amountIdr,
    required String currency,
    int localUserId = 1,
  }) async {
    // 1. Update dana terkumpul kampanye di memori
    final idx = _campaigns.indexWhere((c) => c.id == campaignId);
    if (idx != -1) {
      final old = _campaigns[idx];
      _campaigns[idx] = old.copyWith(
        collectedAmount: old.collectedAmount + amountIdr,
      );
    }

    final campaign = idx != -1 ? _campaigns[idx] : null;
    final campaignTitle = campaign?.title ?? 'Donasi Kebaikan';

    // 2. Ambil blok terakhir dari SQLite untuk chaining
    final latestBlock = await _db.getLatestLedgerEntry();
    final nextBlockIndex = (latestBlock?.blockIndex ?? -1) + 1;
    final previousHash =
        latestBlock?.entryHash ?? LedgerUtils.genesisPreviousHash;
    final donationId = 'don-${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now().toIso8601String();

    // 3. Hitung SHA-256 entry_hash (Bab 4.5 & Bab 8.2)
    final entryHash = LedgerUtils.calculateEntryHash(
      blockIndex: nextBlockIndex,
      donationId: donationId,
      campaignId: campaignId,
      description: 'Simulasi Donasi: $campaignTitle ($currency)',
      amount: amountIdr,
      previousHash: previousHash,
      createdAt: createdAt,
    );

    final newBlock = LedgerModel(
      blockIndex: nextBlockIndex,
      donationId: donationId,
      campaignId: campaignId,
      description: 'Simulasi Donasi: $campaignTitle ($currency)',
      amount: amountIdr,
      previousHash: previousHash,
      entryHash: entryHash,
      createdAt: createdAt,
    );

    // 4. Simpan ke database lokal SQLite
    await _db.insertLedgerEntry(newBlock);

    // 5. Sinkronisasi ke Supabase jika online (RF-004 & RF-007)
    if (_supabase.isAvailable) {
      await _supabase.insertDonation(
        campaignId: campaignId,
        localUserId: localUserId,
        donorName: donorName,
        amountIdr: amountIdr,
        originalCurrency: currency,
        referenceCode: donationId,
      );
      await _supabase.insertLedgerEntry(newBlock);
    }

    return newBlock;
  }
}
