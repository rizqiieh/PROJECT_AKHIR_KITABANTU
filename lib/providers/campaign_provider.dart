import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/models/campaign_model.dart';
import 'package:kitabantu/data/models/ledger_model.dart';
import 'package:kitabantu/data/repositories/campaign_repository.dart';
import 'package:kitabantu/core/utils/ledger_utils.dart';

// ── Kategori terpilih ──
final selectedCategoryProvider = StateProvider<String>((ref) => 'Semua');

// ── Kata kunci pencarian ──
final campaignSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Provider Daftar Kampanye ──
final campaignsListProvider =
    FutureProvider.autoDispose<List<CampaignModel>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(campaignSearchQueryProvider);
  return CampaignRepository.instance
      .getCampaigns(category: category, searchQuery: query);
});

// ── Provider Bookmark Lokal (SQLite RF-004) ──
class BookmarksNotifier extends StateNotifier<AsyncValue<List<CampaignModel>>> {
  BookmarksNotifier() : super(const AsyncValue.loading()) {
    loadBookmarks();
  }

  final _db = DatabaseHelper.instance;

  Future<void> loadBookmarks() async {
    try {
      final list = await _db.getBookmarks();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> isBookmarked(String campaignId) async {
    return _db.isBookmarked(campaignId);
  }

  Future<void> toggleBookmark(CampaignModel campaign) async {
    final exists = await _db.isBookmarked(campaign.id);
    if (exists) {
      await _db.removeBookmark(campaign.id);
    } else {
      await _db.addBookmark(campaign);
    }
    await loadBookmarks();
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, AsyncValue<List<CampaignModel>>>(
  (ref) => BookmarksNotifier(),
);

// ── Provider Ledger Transparansi (RF-007) ──
class LedgerState {
  final List<LedgerModel> entries;
  final LedgerVerificationResult verification;
  final bool isLoading;

  const LedgerState({
    required this.entries,
    required this.verification,
    this.isLoading = false,
  });
}

class LedgerNotifier extends StateNotifier<LedgerState> {
  LedgerNotifier()
      : super(const LedgerState(
          entries: [],
          verification: LedgerVerificationResult(
            isValid: true,
            message: 'Memuat data ledger...',
          ),
          isLoading: true,
        )) {
    loadLedger();
  }

  final _db = DatabaseHelper.instance;

  Future<void> loadLedger() async {
    state = LedgerState(
      entries: state.entries,
      verification: state.verification,
      isLoading: true,
    );

    var list = await _db.getLedgerEntries();

    // Jika database kosong, buat Genesis block perdana
    if (list.isEmpty) {
      const time = '2026-10-20T00:00:00Z';
      final genesisHash = LedgerUtils.calculateEntryHash(
        blockIndex: 0,
        donationId: 'don-genesis',
        campaignId: 'cmp-genesis',
        description: 'Genesis Block KitaBantu Transparansi',
        amount: 0.0,
        previousHash: LedgerUtils.genesisPreviousHash,
        createdAt: time,
      );

      final genesis = LedgerModel(
        blockIndex: 0,
        donationId: 'don-genesis',
        campaignId: 'cmp-genesis',
        description: 'Genesis Block KitaBantu Transparansi',
        amount: 0.0,
        previousHash: LedgerUtils.genesisPreviousHash,
        entryHash: genesisHash,
        createdAt: time,
      );

      await _db.insertLedgerEntry(genesis);
      list = [genesis];
    }

    final blockDataList = list.map((e) => e.toBlockData()).toList();
    final result = LedgerUtils.verifyChain(blockDataList);

    state = LedgerState(
      entries: list,
      verification: result,
      isLoading: false,
    );
  }

  /// Memverifikasi ulang integritas rantai secara eksplisit (RF-007).
  void verifyChainIntegrity() {
    final blockDataList = state.entries.map((e) => e.toBlockData()).toList();
    final result = LedgerUtils.verifyChain(blockDataList);
    state = LedgerState(
      entries: state.entries,
      verification: result,
      isLoading: false,
    );
  }
}

final ledgerProvider = StateNotifierProvider<LedgerNotifier, LedgerState>(
  (ref) => LedgerNotifier(),
);
