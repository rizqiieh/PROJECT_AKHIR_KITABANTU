import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitabantu/data/models/campaign_model.dart';
import 'package:kitabantu/data/models/ledger_model.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const String _url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  // ignore: deprecated_member_use
  static const String _anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  bool _initialized = false;

  bool get isAvailable => _initialized && _url.isNotEmpty && _anonKey.isNotEmpty;

  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('Supabase Config URL: $_url');
    if (_url.isNotEmpty && _anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: _url,
          // ignore: deprecated_member_use
          anonKey: _anonKey,
        );
        _initialized = true;
        debugPrint('Supabase BERHASIL diinisialisasi.');
      } catch (e) {
        debugPrint('Supabase GAGAL inisialisasi: $e');
        _initialized = false;
      }
    } else {
      debugPrint('SUPABASE_URL atau ANON_KEY masih kosong!');
    }
  }

  SupabaseClient? get client => isAvailable ? Supabase.instance.client : null;

  // ==========================================
  // 1. Kampanye (campaigns)
  // ==========================================

  Future<List<CampaignModel>> fetchCampaigns() async {
    final c = client;
    if (c == null) return [];

    try {
      final response = await c
          .from('campaigns')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((map) => CampaignModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Fetch Campaigns Error: $e');
      return [];
    }
  }

  /// Mengunggah daftar kampanye awal jika Supabase masih kosong
  Future<void> seedInitialCampaigns(List<CampaignModel> seedList) async {
    final c = client;
    if (c == null) return;

    try {
      final existing = await c.from('campaigns').select('id').limit(1);
      if ((existing as List).isEmpty) {
        final payload = seedList.map((camp) => camp.toMap()).toList();
        await c.from('campaigns').insert(payload);
        debugPrint('Berhasil menyemai data kampanye ke Supabase.');
      }
    } catch (e) {
      debugPrint('Seed Campaigns Error: $e');
    }
  }

  // ==========================================
  // 2. Donasi (donations)
  // ==========================================

  Future<bool> insertDonation({
    required String campaignId,
    required int localUserId,
    required String donorName,
    required double amountIdr,
    required String originalCurrency,
    required String referenceCode,
  }) async {
    final c = client;
    if (c == null) {
      debugPrint('Insert Donation Gagal: Client Supabase null / isAvailable false');
      return false;
    }

    try {
      await c.from('donations').insert({
        'campaign_id': campaignId,
        'local_user_id': localUserId,
        'donor_name': donorName,
        'amount_idr': amountIdr,
        'original_currency': originalCurrency,
        'reference_code': referenceCode,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Insert Donation ke Supabase BERHASIL!');
      return true;
    } catch (e) {
      debugPrint('Insert Donation Error Supabase: $e');
      return false;
    }
  }

  // ==========================================
  // 3. Ledger Transparansi (ledger_entries)
  // ==========================================

  Future<List<LedgerModel>> fetchLedgerEntries() async {
    final c = client;
    if (c == null) return [];

    try {
      final response = await c
          .from('ledger_entries')
          .select()
          .order('block_index', ascending: true);
      return (response as List)
          .map((map) => LedgerModel.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Fetch Ledger Error: $e');
      return [];
    }
  }

  Future<bool> insertLedgerEntry(LedgerModel block) async {
    final c = client;
    if (c == null) return false;

    try {
      final mapData = block.toMap();
      // Hilangkan block_index agar PostgreSQL mengisi SERIAL-nya secara otomatis
      mapData.remove('block_index');

      await c.from('ledger_entries').insert(mapData);
      return true;
    } catch (e) {
      debugPrint('Insert Ledger Error: $e');
      return false;
    }
  }

  // ==========================================
  // 4. Umpan Balik Mata Kuliah (course_feedback)
  // ==========================================

  Future<bool> insertCourseFeedback({
    required int localUserId,
    required String studentName,
    required String impression,
    required String suggestion,
  }) async {
    final c = client;
    if (c == null) return false;

    try {
      await c.from('course_feedback').insert({
        'local_user_id': localUserId,
        'student_name': studentName,
        'impression': impression,
        'suggestion': suggestion,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Insert Feedback Error: $e');
      return false;
    }
  }
}