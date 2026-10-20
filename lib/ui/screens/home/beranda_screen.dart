import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/providers/campaign_provider.dart';
import 'package:kitabantu/ui/screens/ledger/ledger_screen.dart';
import 'package:kitabantu/ui/screens/map_lbs/map_lbs_screen.dart';
import 'package:kitabantu/ui/screens/minigame/minigame_screen.dart';
import 'package:kitabantu/ui/screens/utilities/converter_screen.dart';
import 'package:kitabantu/ui/screens/utilities/zakat_calculator_screen.dart';
import 'package:kitabantu/ui/widgets/campaign_card.dart';

/// Layar Beranda Utama (Tab 1 — Bab 6 §4).
class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Panti Asuhan',
    'Bencana',
    'Pendidikan',
    'Kesehatan',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final campaignsAsync = ref.watch(campaignsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KitaBantu'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Ledger Transparansi',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LedgerScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(campaignsListProvider),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Sapaan Pengguna ──
              Text(
                'Assalamu\'alaikum, ${user?.fullName ?? 'Hamba Allah'} 👋',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Salurkan kebaikan dan zakat Anda secara aman & transparan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),

              // ── Grid 5 Pintasan Fitur Wajib (Bab 6 §4) ──
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
                children: [
                  _FeatureShortcut(
                    icon: Icons.map_outlined,
                    label: 'Peta LBS',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MapLbsScreen()),
                    ),
                  ),
                  _FeatureShortcut(
                    icon: Icons.calculate_outlined,
                    label: 'Zakat AI',
                    color: AppColors.primaryDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ZakatCalculatorScreen()),
                    ),
                  ),
                  _FeatureShortcut(
                    icon: Icons.currency_exchange,
                    label: 'Kurs/Waktu',
                    color: AppColors.secondaryDark,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ConverterScreen()),
                    ),
                  ),
                  _FeatureShortcut(
                    icon: Icons.link,
                    label: 'Ledger',
                    color: AppColors.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LedgerScreen()),
                    ),
                  ),
                  _FeatureShortcut(
                    icon: Icons.sports_esports_outlined,
                    label: 'Mini-Game',
                    color: AppColors.warning,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MinigameScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Kolom Pencarian Kampanye ──
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari panti asuhan, bencana, atau kota...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(campaignSearchQueryProvider.notifier).state =
                                '';
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  ref.read(campaignSearchQueryProvider.notifier).state = val;
                },
              ),
              const SizedBox(height: 14),

              // ── Filter Kategori Chips ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) {
                            ref
                                .read(selectedCategoryProvider.notifier)
                                .state = cat;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Daftar Kampanye ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Program Kebaikan Terpilih',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedCategoryProvider.notifier).state =
                          'Semua';
                      _searchController.clear();
                      ref.read(campaignSearchQueryProvider.notifier).state = '';
                    },
                    child: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              campaignsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text('Gagal memuat kampanye: $err'),
                  ),
                ),
                data: (campaigns) {
                  if (campaigns.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: campaigns.length,
                    itemBuilder: (ctx, idx) {
                      return CampaignCard(campaign: campaigns[idx]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'Tidak Ada Kampanye yang Cocok',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci atau pilih kategori lain.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget tombol pintasan fitur bulat / modern di Beranda.
class _FeatureShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureShortcut({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
