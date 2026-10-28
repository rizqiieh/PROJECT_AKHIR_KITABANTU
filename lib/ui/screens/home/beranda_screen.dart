import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/core/services/notification_service.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/models/wallet_transaction_model.dart';
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



  void _showTopUpBottomSheet(BuildContext context) {



    showModalBottomSheet(



      context: context,



      isScrollControlled: true,



      backgroundColor: Colors.transparent,



      builder: (ctx) => const _TopUpBottomSheet(),



    );



  }



  void _showWalletHistoryBottomSheet(BuildContext context) {



    showModalBottomSheet(



      context: context,



      isScrollControlled: true,



      backgroundColor: Colors.transparent,



      builder: (ctx) => const _WalletHistoryBottomSheet(),



    );



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



              



                            borderRadius: BorderRadius.circular(10),



                          ),



                          child: Image.asset(
  'assets/images/LogoKitaBantu.png',
  width: 32,
  height: 32,
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



                      Row(



                        mainAxisAlignment: MainAxisAlignment.spaceBetween,



                        crossAxisAlignment: CrossAxisAlignment.center,



                        children: [



                          Expanded(



                            child: Column(



                              crossAxisAlignment: CrossAxisAlignment.start,



                              children: [



                                Text(



                                  CurrencyUtils.formatIdr(user?.balance ?? 1000000.0),



                                  style: const TextStyle(



                                    fontSize: 24,



                                    fontWeight: FontWeight.w800,



                                    color: Color(0xFF1B3B2B),



                                  ),



                                ),



                                const SizedBox(height: 2),



                                const Text(



                                  'Tersimpan aman di SQLite lokal',



                                  style: TextStyle(



                                    fontSize: 11,



                                    color: Color(0xFF718096),



                                  ),



                                ),



                              ],



                            ),



                          ),



                          Row(



                            children: [



                              IconButton(



                                onPressed: () => _showWalletHistoryBottomSheet(context),



                                icon: const Icon(Icons.history_rounded, color: Color(0xFF26533C)),



                                tooltip: 'Riwayat Transaksi',



                              ),



                              ElevatedButton.icon(



                                onPressed: () => _showTopUpBottomSheet(context),



                                icon: const Icon(Icons.add_circle_outline, size: 14),



                                label: const Text(



                                  'Top Up',



                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),



                                ),



                                style: ElevatedButton.styleFrom(



                                  backgroundColor: const Color(0xFF26533C),



                                  foregroundColor: Colors.white,



                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),



                                  shape: RoundedRectangleBorder(



                                    borderRadius: BorderRadius.circular(10),



                                  ),



                                  elevation: 0,



                                ),



                              ),



                            ],



                          ),



                        ],



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

                  color: _isHoveredOrPressed

                      ? const Color(0xFF26533C)

                      : const Color(0xFFEAF5EE),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: Icon(

                  widget.icon,

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



/// Bottom Sheet Interaktif Top Up Saldo Kantong Amanah (Simulasi SQLite)

class _TopUpBottomSheet extends ConsumerStatefulWidget {

  const _TopUpBottomSheet();



  @override

  ConsumerState<_TopUpBottomSheet> createState() => _TopUpBottomSheetState();

}



class _TopUpBottomSheetState extends ConsumerState<_TopUpBottomSheet> {

  final _amountController = TextEditingController(text: '100000');

  double _selectedAmount = 100000.0;

  String _selectedMethod = 'QRIS';

  bool _isProcessing = false;



  final List<double> _presets = [

    20000.0,

    50000.0,

    100000.0,

    250000.0,

    500000.0,

    1000000.0,

  ];



  final List<Map<String, dynamic>> _methods = [

    {

      'id': 'QRIS',

      'name': 'QRIS (Gopay, OVO, Dana, LinkAja, ShopeePay)',

      'icon': Icons.qr_code_2_rounded,

    },

    {

      'id': 'BCA VA',

      'name': 'BCA Virtual Account',

      'icon': Icons.account_balance_rounded,

    },

    {

      'id': 'Mandiri VA',

      'name': 'Mandiri Virtual Account',

      'icon': Icons.account_balance_rounded,

    },

    {

      'id': 'BSI VA',

      'name': 'BSI Virtual Account (Syariah)',

      'icon': Icons.account_balance_rounded,

    },

  ];



  @override

  void dispose() {

    _amountController.dispose();

    super.dispose();

  }



  void _setAmount(double val) {

    setState(() {

      _selectedAmount = val;

      _amountController.text = val.toInt().toString();

    });

  }



  Future<void> _processTopUp() async {

    if (_selectedAmount < 10000) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Minimal top up adalah Rp 10.000'),

          backgroundColor: Colors.red,

        ),

      );

      return;

    }



    setState(() => _isProcessing = true);



    try {

      final success = await ref.read(authProvider.notifier).topUpBalance(

            _selectedAmount,

            method: _selectedMethod,

          );



      if (!success) {

        throw Exception('Gagal memperbarui saldo di database SQLite.');

      }



      final updatedUser = ref.read(authProvider).user;

      final newBalanceStr = CurrencyUtils.formatIdr(updatedUser?.balance ?? 0.0);

      final addedAmountStr = CurrencyUtils.formatIdr(_selectedAmount);



      // Trigger Notifikasi Lokal Status Bar

      await NotificationService.instance.showTopUpSuccessNotification(

        amountFormatted: addedAmountStr,

        newBalanceFormatted: newBalanceStr,

      );



      if (!mounted) return;

      Navigator.pop(context);



      // Tampilkan Dialog Sukses

      showDialog(

        context: context,

        builder: (ctx) => AlertDialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF26533C), size: 54),

          title: const Text('Top Up Berhasil!', style: TextStyle(fontWeight: FontWeight.bold)),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text('Saldo Kantong Amanah Anda berhasil ditambahkan ke database SQLite:'),

              const SizedBox(height: 12),

              _dialogRow('Nominal Masuk:', addedAmountStr),

              _dialogRow('Metode Pembayaran:', _selectedMethod),

              _dialogRow('Total Saldo Saat Ini:', newBalanceStr),

              const SizedBox(height: 8),

              Container(

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(

                  color: const Color(0xFFE8F5E9),

                  borderRadius: BorderRadius.circular(8),

                ),

                child: const Row(

                  children: [

                    Icon(Icons.shield_outlined, size: 16, color: Color(0xFF26533C)),

                    SizedBox(width: 6),

                    Expanded(

                      child: Text(

                        'Data saldo tersimpan aman dan terintegrasi penuh.',

                        style: TextStyle(fontSize: 11, color: Color(0xFF26533C)),

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

          actions: [

            ElevatedButton(

              onPressed: () => Navigator.pop(ctx),

              style: ElevatedButton.styleFrom(

                backgroundColor: const Color(0xFF26533C),

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

              ),

              child: const Text('Tutup'),

            ),

          ],

        ),

      );

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text('Terjadi kesalahan: $e'),

            backgroundColor: Colors.red,

          ),

        );

      }

    } finally {

      if (mounted) setState(() => _isProcessing = false);

    }

  }



  Widget _dialogRow(String label, String value) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 3),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),

          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B3B2B))),

        ],

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: EdgeInsets.only(

        left: 20,

        right: 20,

        top: 20,

        bottom: MediaQuery.of(context).viewInsets.bottom + 20,

      ),

      decoration: const BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      child: SingleChildScrollView(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Container(

                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(

                    color: const Color(0xFF26533C).withValues(alpha: 0.1),

                    borderRadius: BorderRadius.circular(10),

                  ),

                  child: const Icon(Icons.add_card_rounded, color: Color(0xFF26533C), size: 22),

                ),

                const SizedBox(width: 10),

                const Text(

                  'Top Up Kantong Amanah',

                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3B2B)),

                ),

                const Spacer(),

                IconButton(

                  icon: const Icon(Icons.close),

                  onPressed: () => Navigator.pop(context),

                ),

              ],

            ),

            const Divider(height: 24),



            // Pilihan nominal cepat

            const Text(

              'Pilih Nominal Top Up:',

              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D3748)),

            ),

            const SizedBox(height: 10),

            Wrap(

              spacing: 8,

              runSpacing: 8,

              children: _presets.map((amt) {

                final isSelected = _selectedAmount == amt;

                return ChoiceChip(

                  label: Text(CurrencyUtils.formatIdr(amt)),

                  selected: isSelected,

                  selectedColor: const Color(0xFF26533C),

                  backgroundColor: const Color(0xFFF0F4F2),

                  labelStyle: TextStyle(

                    fontSize: 12,

                    fontWeight: FontWeight.w600,

                    color: isSelected ? Colors.white : const Color(0xFF2D3748),

                  ),

                  onSelected: (val) {

                    if (val) _setAmount(amt);

                  },

                );

              }).toList(),

            ),

            const SizedBox(height: 14),



            // Input nominal manual

            TextField(

              controller: _amountController,

              keyboardType: TextInputType.number,

              decoration: InputDecoration(

                prefixText: 'Rp ',

                labelText: 'Nominal Lainnya',

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

              ),

              onChanged: (val) {

                final parsed = double.tryParse(val) ?? 0;

                setState(() => _selectedAmount = parsed);

              },

            ),

            const SizedBox(height: 18),



            // Pilihan Metode Pembayaran

            const Text(

              'Metode Pembayaran (Simulasi):',

              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D3748)),

            ),

            const SizedBox(height: 10),

            Column(

              children: _methods.map((m) {

                final isSelected = _selectedMethod == m['id'];

                return Container(

                  margin: const EdgeInsets.only(bottom: 8),

                  decoration: BoxDecoration(

                    color: isSelected ? const Color(0xFFEAF5EE) : Colors.white,

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(

                      color: isSelected ? const Color(0xFF26533C) : const Color(0xFFE2E8F0),

                      width: isSelected ? 1.5 : 1,

                    ),

                  ),

                  child: ListTile(

                    dense: true,

                    leading: Icon(m['icon'] as IconData, color: isSelected ? const Color(0xFF26533C) : Colors.grey),

                    title: Text(

                      m['name'] as String,

                      style: TextStyle(

                        fontSize: 12,

                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,

                        color: isSelected ? const Color(0xFF1B3B2B) : const Color(0xFF4A5568),

                      ),

                    ),

                    trailing: isSelected

                        ? const Icon(Icons.check_circle, color: Color(0xFF26533C), size: 18)

                        : null,

                    onTap: () => setState(() => _selectedMethod = m['id'] as String),

                  ),

                );

              }).toList(),

            ),

            const SizedBox(height: 18),



            // Tombol Bayar

            SizedBox(

              width: double.infinity,

              height: 48,

              child: ElevatedButton(

                onPressed: _isProcessing ? null : _processTopUp,

                style: ElevatedButton.styleFrom(

                  backgroundColor: const Color(0xFF26533C),

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                  elevation: 0,

                ),

                child: _isProcessing

                    ? const SizedBox(

                        height: 20,

                        width: 20,

                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),

                      )

                    : Text(

                        'Konfirmasi Top Up ${CurrencyUtils.formatIdr(_selectedAmount)}',

                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),

                      ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}



/// Bottom Sheet Menampilkan Riwayat Mutasi Dompet (Top Up & Donasi)

class _WalletHistoryBottomSheet extends ConsumerWidget {

  const _WalletHistoryBottomSheet();



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final user = ref.watch(authProvider).user;

    final userId = user?.id ?? 0;



    return Container(

      constraints: BoxConstraints(

        maxHeight: MediaQuery.of(context).size.height * 0.75,

      ),

      padding: const EdgeInsets.all(20),

      decoration: const BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(

                  color: const Color(0xFF26533C).withValues(alpha: 0.1),

                  borderRadius: BorderRadius.circular(10),

                ),

                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF26533C), size: 22),

              ),

              const SizedBox(width: 10),

              const Text(

                'Riwayat Transaksi Kantong',

                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3B2B)),

              ),

              const Spacer(),

              IconButton(

                icon: const Icon(Icons.close),

                onPressed: () => Navigator.pop(context),

              ),

            ],

          ),

          const Divider(height: 24),

          Expanded(

            child: FutureBuilder<List<WalletTransactionModel>>(

              future: DatabaseHelper.instance.getWalletTransactions(userId),

              builder: (ctx, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {

                  return const Center(child: CircularProgressIndicator());

                }

                final list = snapshot.data ?? [];

                if (list.isEmpty) {

                  return Center(

                    child: Column(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: const [

                        Icon(Icons.account_balance_wallet_outlined, size: 54, color: Colors.black26),

                        SizedBox(height: 12),

                        Text('Belum Ada Mutasi Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),

                        SizedBox(height: 4),

                        Text('Top Up atau Donasi Anda akan tercatat di sini.', style: TextStyle(fontSize: 12, color: Colors.black38)),

                      ],

                    ),

                  );

                }



                return ListView.separated(

                  itemCount: list.length,

                  separatorBuilder: (_, _) => const Divider(height: 12),

                  itemBuilder: (ctx, idx) {

                    final item = list[idx];

                    final isTopUp = item.type == 'TOPUP';

                    return ListTile(

                      contentPadding: EdgeInsets.zero,

                      leading: Container(

                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(

                          color: isTopUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),

                          shape: BoxShape.circle,

                        ),

                        child: Icon(

                          isTopUp ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,

                          color: isTopUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828),

                          size: 18,

                        ),

                      ),

                      title: Text(

                        item.description,

                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),

                      ),

                      subtitle: Text(

                        'Ref: ${item.referenceId ?? '-'} • ${item.createdAt.split('T').first}',

                        style: const TextStyle(fontSize: 11, color: Colors.black45),

                      ),

                      trailing: Text(

                        '${isTopUp ? '+' : '-'} ${CurrencyUtils.formatIdr(item.amount)}',

                        style: TextStyle(

                          fontSize: 13,

                          fontWeight: FontWeight.bold,

                          color: isTopUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828),

                        ),

                      ),

                    );

                  },

                );

              },

            ),

          ),

        ],

      ),

    );

  }

}

