import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/providers/campaign_provider.dart';
import 'package:kitabantu/ui/screens/ledger/ledger_screen.dart';
import 'package:kitabantu/ui/screens/map_lbs/map_lbs_screen.dart';
import 'package:kitabantu/ui/screens/minigame/minigame_screen.dart';
import 'package:kitabantu/ui/screens/utilities/converter_screen.dart';
import 'package:kitabantu/ui/screens/utilities/zakat_calculator_screen.dart';
import 'package:kitabantu/ui/widgets/campaign_card.dart';
import '../campaign/scan_receipt_screen.dart';

/// Layar Beranda Utama — Tampilan Modern sesuai Desain Stitch AI.
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
      backgroundColor: const Color(0xFFF1F8F4), // Latar hijau sage lembut Stitch
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(campaignsListProvider),
          color: const Color(0xFF26533C),
          child: SingleChildScrollView(
            
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar: Logo & Notifikasi ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF26533C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.volunteer_activism,
                            color: Color(0xFF26533C),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'KitaBantu',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B3B2B),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: const Color(0xFF1B3B2B),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Belum ada notifikasi baru'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Header Sapaan Pengguna ──
                Text(
                  'Assalamu\'alaikum, ${user?.fullName.split(' ').first ?? 'Ahmad'}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3B2B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mari tebarkan manfaat dan kebaikan hari ini.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A6E63),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Card: Kantong Amanah Anda ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF26533C),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Kantong Amanah Anda',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F4EC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Terverifikasi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF26533C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Rp 1.450.000',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3B2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tersimpan aman untuk distribusi ziswaf terjadwal',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF718096),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const MapLbsScreen()),
                                );
                              },
                              icon: const Icon(Icons.send_rounded, size: 14),
                              label: const Text(
                                'Kirim Donasi',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF26533C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen()),
                                );
                              },
                              icon: const Icon(Icons.calculate_outlined, size: 15, color: Color(0xFF26533C)),
                              label: const Text(
                                'Kalkulator Zakat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF26533C),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFEBF6F0),
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Section: Layanan Unggulan (Grid 3x2) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Layanan Unggulan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3B2B),
                      ),
                    ),
                    Text(
                      'Gotong Royong',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF26533C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  children: [
                    _StitchMenuCard(
                      icon: Icons.location_on_outlined,
                      label: 'Peta Bantuan',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MapLbsScreen()),
                      ),
                    ),
                    _StitchMenuCard(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Kalkulator AI',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen()),
                      ),
                    ),
                    _StitchMenuCard(
                      icon: Icons.currency_exchange_rounded,
                      label: 'Kurs & Waktu',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ConverterScreen()),
                      ),
                    ),
                    _StitchMenuCard(
                      icon: Icons.verified_user_outlined,
                      label: 'Ledger Sahih',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LedgerScreen()),
                      ),
                    ),
                    _StitchMenuCard(
                      icon: Icons.sports_esports_outlined,
                      label: 'Mini-Game',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MinigameScreen()),
                      ),
                    ),
                    _StitchMenuCard(
                      icon: Icons.document_scanner_outlined,
                       label: 'AI Scan Nota',
                       onTap: () {
                      Navigator.of(context).push(
                       MaterialPageRoute(builder: (_) => const ScanReceiptScreen()),
                            );
                          },
                        ),
                  ],
                ),
                const SizedBox(height: 22),
// ── Input Cari Kampanye (RF-004) ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari kampanye atau lokasi...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF718096)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onChanged: (query) {
                        setState(() {});
                      },
                    ),
                  ),

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
                          selectedColor: const Color(0xFF26533C),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : Colors.black12,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF4A5568),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              ref.read(selectedCategoryProvider.notifier).state = cat;
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Section: Mendekati Deadline ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Mendekati Deadline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3B2B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Mendesak',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE53E3E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(selectedCategoryProvider.notifier).state = 'Semua';
                        _searchController.clear();
                        ref.read(campaignSearchQueryProvider.notifier).state = '';
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF26533C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Daftar Kampanye ──
                campaignsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: Color(0xFF26533C)),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text('Gagal memuat kampanye: $err'),
                    ),
                  ),
                  data: (campaigns) {
                    final query = _searchController.text.toLowerCase();
    final filteredList = campaigns.where((item) {
      final matchesCategory = selectedCategory == 'Semua' || item.category == selectedCategory;
      final matchesSearch = item.title.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
                    if (filteredList.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        return CampaignCard(campaign: filteredList[idx]);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
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
          children: const [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Tidak Ada Kampanye yang Cocok',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748)),
            ),
            SizedBox(height: 4),
            Text(
              'Coba ubah kata kunci atau pilih kategori lain.',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget Kartu Menu 3x2 Gaya Stitch AI
/// Widget Kartu Menu Interaktif dengan Animasi Tekan & Hover
class _StitchMenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StitchMenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_StitchMenuCard> createState() => _StitchMenuCardState();
}

class _StitchMenuCardState extends State<_StitchMenuCard> {
  bool _isHoveredOrPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHoveredOrPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        onHighlightChanged: (value) {
          setState(() => _isHoveredOrPressed = value);
        },
        onHover: (value) {
          setState(() => _isHoveredOrPressed = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _isHoveredOrPressed
                    ? const Color(0xFF26533C).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHoveredOrPressed ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  // Berubah menjadi hijau tua saat ditekan, hijau muda lembut saat normal
                  color: _isHoveredOrPressed
                      ? const Color(0xFF26533C)
                      : const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  // Ikon berubah putih saat aktif, hijau tua saat normal
                  color: _isHoveredOrPressed
                      ? Colors.white
                      : const Color(0xFF26533C),
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      _isHoveredOrPressed ? FontWeight.w700 : FontWeight.w600,
                  color: _isHoveredOrPressed
                      ? const Color(0xFF1B3B2B)
                      : const Color(0xFF2D3748),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}