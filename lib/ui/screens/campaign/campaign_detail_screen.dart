import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/services/notification_service.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/core/utils/time_zone_utils.dart';
import 'package:kitabantu/data/models/campaign_model.dart';
import 'package:kitabantu/data/repositories/campaign_repository.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/providers/campaign_provider.dart';


/// Halaman Detail Kampanye & Simulasi Donasi (Bab 6 §5).
class CampaignDetailScreen extends ConsumerStatefulWidget {
  final CampaignModel campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  ConsumerState<CampaignDetailScreen> createState() =>
      _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends ConsumerState<CampaignDetailScreen> {
  late CampaignModel _campaign;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final bookmarked =
        await ref.read(bookmarksProvider.notifier).isBookmarked(_campaign.id);
    if (mounted) {
      setState(() => _isBookmarked = bookmarked);
    }
  }

  Future<void> _toggleBookmark() async {
    await ref.read(bookmarksProvider.notifier).toggleBookmark(_campaign);
    final nowBookmarked = !_isBookmarked;
    setState(() => _isBookmarked = nowBookmarked);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nowBookmarked
              ? 'Kampanye disimpan ke favorit (SQLite) ✓'
              : 'Kampanye dihapus dari favorit'),
          backgroundColor:
              nowBookmarked ? AppColors.success : AppColors.onSurfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final endsAtDate = DateTime.tryParse(_campaign.endsAt) ?? DateTime.now();
    final timeZones = TimeZoneUtils.formatAllFourZones(endsAtDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kampanye'),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.amberAccent : AppColors.onPrimary,
            ),
            tooltip: 'Simpan Favorit (SQLite)',
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Ingatkan Kampanye',
            onPressed: _setReminder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Kategori & Lokasi ──
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _campaign.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _campaign.locationLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Judul ──
            Text(
              _campaign.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
            ),
            const SizedBox(height: 16),

            // ── Card Progres Dana ──
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dana Terkumpul',
                            style: TextStyle(color: AppColors.onSurfaceVariant)),
                        Text(
                          '${(_campaign.progressPercentage * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _campaign.progressPercentage,
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyUtils.formatIdr(_campaign.collectedAmount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text('terkumpul',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyUtils.formatIdr(_campaign.targetAmount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Text('target',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Batas Waktu Serempak di 4 Zona (RF-006) ──
            Card(
              margin: EdgeInsets.zero,
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.schedule, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Batas Waktu Kampanye (4 Zona Waktu):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildZoneRow('🇮🇩 WIB (Jakarta):', timeZones['WIB'] ?? ''),
                    const SizedBox(height: 4),
                    _buildZoneRow('🇮🇩 WITA (Makassar):', timeZones['WITA'] ?? ''),
                    const SizedBox(height: 4),
                    _buildZoneRow('🇮🇩 WIT (Jayapura):', timeZones['WIT'] ?? ''),
                    const SizedBox(height: 4),
                    _buildZoneRow('🇬🇧 London (BST/GMT):', timeZones['London'] ?? ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Deskripsi Kampanye ──
            Text(
              'Cerita Penggalangan Dana',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _campaign.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // ── Info Koordinat LBS ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.explore_outlined, color: AppColors.secondaryDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Koordinat GPS: ${_campaign.latitude.toStringAsFixed(4)}, ${_campaign.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Jarak untuk floating button di bawah
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showDonationBottomSheet,
              icon: const Icon(Icons.favorite),
              label: const Text('Donasi Sekarang (Simulasi)'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _setReminder() async {
    await NotificationService.instance.showCampaignReminderNotification(
      campaignTitle: _campaign.title,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pengingat kampanye berhasil diaktifkan! ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showDonationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DonationBottomSheet(
        campaign: _campaign,
        onDonationSuccess: (amount) {
          setState(() {
            _campaign = _campaign.copyWith(
              collectedAmount: _campaign.collectedAmount + amount,
            );
          });
          ref.invalidate(campaignsListProvider);
          ref.read(ledgerProvider.notifier).loadLedger();
        },
      ),
    );
  }
}

/// Bottom Sheet Interaktif Simulasi Donasi (Bab 6 §5).
class _DonationBottomSheet extends ConsumerStatefulWidget {
  final CampaignModel campaign;
  final Function(double) onDonationSuccess;

  const _DonationBottomSheet({
    required this.campaign,
    required this.onDonationSuccess,
  });

  @override
  ConsumerState<_DonationBottomSheet> createState() =>
      _DonationBottomSheetState();
}

class _DonationBottomSheetState extends ConsumerState<_DonationBottomSheet> {
  final _amountController = TextEditingController(text: '50000');
  double _selectedAmount = 50000.0;
  bool _isProcessing = false;

  final List<double> _presetAmounts = [
    20000.0,
    50000.0,
    100000.0,
    250000.0,
    500000.0,
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyConversions = CurrencyUtils.convertIdrToAll(_selectedAmount);
    final userBalance = ref.watch(authProvider).user?.balance ?? 0.0;
    final isBalanceInsufficient = userBalance < _selectedAmount;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Simulasi Donasi Demo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // ── Info Saldo Kantong Amanah Pengguna ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isBalanceInsufficient
                  ? AppColors.error.withValues(alpha: 0.1)
                  : const Color(0xFFEAF5EE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isBalanceInsufficient
                    ? AppColors.error.withValues(alpha: 0.5)
                    : const Color(0xFF26533C).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: isBalanceInsufficient ? AppColors.error : const Color(0xFF26533C),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Saldo Kantong Amanah:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  CurrencyUtils.formatIdr(userBalance),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isBalanceInsufficient ? AppColors.error : const Color(0xFF26533C),
                  ),
                ),
              ],
            ),
          ),
          if (isBalanceInsufficient) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ Saldo tidak mencukupi (Kurang ${CurrencyUtils.formatIdr(_selectedAmount - userBalance)}). Kurangi nominal atau lakukan Top Up di Beranda.',
              style: const TextStyle(fontSize: 11, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 12),

          // ── Pilihan Nominal Cepat ──
          const Text('Pilih Nominal:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetAmounts.map((amt) {
              final isSelected = _selectedAmount == amt;
              return ChoiceChip(
                label: Text(CurrencyUtils.formatIdr(amt)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedAmount = amt;
                      _amountController.text = amt.toStringAsFixed(0);
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Input Nominal Custom ──
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              labelText: 'Atau Masukkan Nominal Lain',
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              setState(() => _selectedAmount = parsed);
            },
          ),
          const SizedBox(height: 16),

          // ── Pratinjau Konversi 4 Mata Uang (RF-006) ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pratinjau Nilai Tukar:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCurrencyBadge('USD', currencyConversions['USD'] ?? 0),
                    _buildCurrencyBadge('EUR', currencyConversions['EUR'] ?? 0),
                    _buildCurrencyBadge('GBP', currencyConversions['GBP'] ?? 0),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tombol Bayar Simulasi ──
        // -- Tombol Bayar Simulasi --
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing || _selectedAmount <= 0 || isBalanceInsufficient
                ? null
                : () async {
                    if (userBalance < _selectedAmount) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Saldo Kantong Amanah tidak mencukupi (${CurrencyUtils.formatIdr(userBalance)}). Silakan Top Up terlebih dahulu.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    setState(() => _isProcessing = true);
                    try {
                      // 1. Update dana terkumpul ke Supabase
                      final repo = CampaignRepository.instance;
                      await repo.donateToCampaign(
                        campaignId: widget.campaign.id,
                        currentCollected: widget.campaign.collectedAmount,
                        donationAmount: _selectedAmount.toDouble(),
                      );

                      // 2. Jalankan proses donasi bawaan (pemotongan saldo & buku kas / ledger)
                      await _processDonation();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(content: Text('Gagal donasi: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Konfirmasi Pembayaran'),
          ),
        ),
      ],
    ),
  );
}
  Widget _buildCurrencyBadge(String code, double value) {
    return Column(
      children: [
        Text(code, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
        Text(
          CurrencyUtils.formatCurrency(value, code),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _processDonation() async {
    if (_selectedAmount <= 0) return;

    setState(() => _isProcessing = true);

    final user = ref.read(authProvider).user;
    final donorName = user?.fullName ?? 'Hamba Allah';

    // 1. Catat ke Ledger dan hitung SHA-256
    final newBlock =
        await CampaignRepository.instance.recordDonationAndCreateBlock(
      campaignId: widget.campaign.id,
      donorName: donorName,
      amountIdr: _selectedAmount,
      currency: 'IDR',
    );

    // 1.5 Potong saldo Kantong Amanah pengguna di SQLite
    await ref.read(authProvider.notifier).deductBalance(
      _selectedAmount,
      description: 'Donasi ke ${widget.campaign.title}',
      referenceId: newBlock.donationId,
    );

    // 2. Memicu notifikasi lokal di status bar (RF-009)
    await NotificationService.instance.showDonationSuccessNotification(
      campaignTitle: widget.campaign.title,
      amountFormatted: CurrencyUtils.formatIdr(_selectedAmount),
      referenceCode: newBlock.donationId,
    );

    setState(() => _isProcessing = false);

    widget.onDonationSuccess(_selectedAmount);

    if (!mounted) return;
    Navigator.pop(context);

    // Tampilkan Dialog Sukses Ledger
    _showSuccessDialog(newBlock);
  }

  void _showSuccessDialog(dynamic block) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 52),
        title: const Text('Alhamdulillah!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simulasi donasi Anda telah berhasil dicatat ke Ledger Blockchain:'),
            const SizedBox(height: 12),
            _infoRow('Blok Index:', '#${block.blockIndex}'),
            _infoRow('Nominal:', CurrencyUtils.formatIdr(block.amount)),
            _infoRow('Ref ID:', block.donationId),
            const SizedBox(height: 6),
            const Text('Entry Hash (SHA-256):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text(
              block.entryHash,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
