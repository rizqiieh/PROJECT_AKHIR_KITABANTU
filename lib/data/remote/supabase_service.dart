import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kitabantu/data/models/campaign_model.dart';
import 'package:kitabantu/data/models/ledger_model.dart';

/// Layanan Komunikasi Supabase Database Online (RF-004 & Bab 8.2).
///
/// Membaca konfigurasi dari environment (secret key tidak di-hardcode):
/// `--dart-define=SUPABASE_URL=https://xyz.supabase.co`
/// `--dart-define=SUPABASE_ANON_KEY=eyJ...`
///
/// Jika kredensial belum diisi, layanan otomatis beroperasi dalam mode
/// offline/lokal secara anggun (graceful fallback) tanpa menyebabkan crash.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const String _url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  // ignore: deprecated_member_use
  static const String _anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  bool _initialized = false;

  /// Memeriksa apakah Supabase online telah dikonfigurasi dan aktif.
  bool get isAvailable => _initialized && _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Inisialisasi Supabase client.
  Future<void> initialize() async {
    if (_initialized) return;

    if (_url.isNotEmpty && _anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: _url,
          // ignore: deprecated_member_use
          anonKey: _anonKey,
        );
        _initialized = true;
      } catch (_) {
        _initialized = false;
      }
    }
  }

  SupabaseClient? get client => isAvailable ? Supabase.instance.client : null;

  // ══════════════════════════════════════════════════════
  //  1. Tabel `campaigns` (Online)
  // ══════════════════════════════════════════════════════

  Future<List<CampaignModel>> fetchCampaigns() async {
    final c = client;
    if (c == null) return [];

    try {
      final response = await c
          .from('campaigns')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((map) => CampaignModel.fromMap(map)).toList();
    } catch (_) {
      return [];
    }
  }

  // ══════════════════════════════════════════════════════
  //  2. Tabel `donations` (Online)
  // ══════════════════════════════════════════════════════

  Future<bool> insertDonation({
    required String campaignId,
    required int localUserId,
    required String donorName,
    required double amountIdr,
    required String originalCurrency,
    required String referenceCode,
  }) async {
    final c = client;
    if (c == null) return false;

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
      return true;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════
  //  3. Tabel `ledger_entries` (Online Hash-Chain RF-007)
  // ══════════════════════════════════════════════════════

  Future<List<LedgerModel>> fetchLedgerEntries() async {
    final c = client;
    if (c == null) return [];

    try {
      final response = await c
          .from('ledger_entries')
          .select()
          .order('block_index', ascending: true);
      return (response as List).map((map) => LedgerModel.fromMap(map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> insertLedgerEntry(LedgerModel block) async {
    final c = client;
    if (c == null) return false;

    try {
      await c.from('ledger_entries').insert(block.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════
  //  4. Tabel `course_feedback` (Online RF-003)
  // ══════════════════════════════════════════════════════

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
    } catch (_) {
      return false;
    }
  }
}
