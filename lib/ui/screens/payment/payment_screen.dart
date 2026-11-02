import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/core/services/notification_service.dart';
import 'package:kitabantu/core/utils/currency_utils.dart';
import 'package:kitabantu/providers/auth_provider.dart';

// ══════════════════════════════════════════════════════
//  Alur pembayaran Top Up (simulasi)
//
//  1. Pengguna memilih nominal + metode di bottom sheet Top Up (Beranda).
//  2. Dibuat PaymentSession → halaman PaymentWaitingScreen
//     ("Menunggu pembayaran": rincian, status, batas waktu).
//  3. "Lihat instruksi pembayaran" → PaymentInstructionScreen
//     (QR untuk QRIS / nomor Virtual Account untuk bank, hitung mundur,
//     panduan pembayaran).
//  4. Saldo baru bertambah SETELAH pembayaran dinyatakan berhasil.
//
//  Belum ada payment gateway sungguhan, jadi tersedia tombol
//  "Simulasikan Pembayaran Berhasil" untuk keperluan demo.
// ══════════════════════════════════════════════════════

const _pageBg = Color(0xFFF1F8F4);
const _ink = Color(0xFF1B3B2B);

const _monthsFull = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];
const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

String _two(int n) => n.toString().padLeft(2, '0');

/// Contoh: "30 Oktober 2026 - 15:43"
String _formatDate(DateTime d) =>
    '${d.day} ${_monthsFull[d.month - 1]} ${d.year} - ${_two(d.hour)}:${_two(d.minute)}';

/// Contoh: "Jumat, 30 Okt 2026 15:58"
String _formatBannerDeadline(DateTime d) =>
    '${_days[d.weekday - 1]}, ${d.day} ${_monthsShort[d.month - 1]} ${d.year} ${_two(d.hour)}:${_two(d.minute)}';

/// Contoh: "00:14:56"
String _formatCountdown(Duration d) =>
    '${_two(d.inHours)}:${_two(d.inMinutes.remainder(60))}:${_two(d.inSeconds.remainder(60))}';

final _rng = Random();
String _randomDigits(int n) => List.generate(n, (_) => _rng.nextInt(10)).join();

const _vaPrefixes = {
  'BCA VA': '39358',
  'Mandiri VA': '88908',
  'BSI VA': '9004',
};

String _generateVa(String method) {
  final prefix = _vaPrefixes[method] ?? '8800';
  return prefix + _randomDigits(16 - prefix.length);
}

String _groupDigits(String s) =>
    RegExp(r'.{1,4}').allMatches(s).map((m) => m.group(0)!).join(' ');

// ══════════════════════════════════════════════════════
//  Model sesi pembayaran
// ══════════════════════════════════════════════════════

enum PaymentStatus { pending, paid, expired }

/// Hasil ketika pengguna meninggalkan halaman pembayaran.
/// - done         : selesai / dibatalkan → kembali ke Beranda
/// - changeMethod : kembali ke pilihan nominal & metode untuk memilih ulang
enum PaymentExit { done, changeMethod }

class PaymentSession extends ChangeNotifier {
  PaymentSession({required this.amount, required this.method})
      : createdAt = DateTime.now(),
        referenceId = _randomDigits(9),
        vaNumber = method == 'QRIS' ? null : _generateVa(method) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  static const Duration validity = Duration(minutes: 15);

  final double amount;
  final String method; // 'QRIS', 'BCA VA', 'Mandiri VA', 'BSI VA'
  final DateTime createdAt;
  final String referenceId;
  final String? vaNumber;

  Timer? _timer;
  PaymentStatus _status = PaymentStatus.pending;

  PaymentStatus get status => _status;
  bool get isPending => _status == PaymentStatus.pending;
  bool get isQris => method == 'QRIS';
  String get bankName => method.replaceAll(' VA', '');
  DateTime get expiresAt => createdAt.add(validity);
  String get qrPayload => 'KITABANTU-QRIS|$referenceId|${amount.toInt()}';

  Duration get remaining {
    final d = expiresAt.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  void markPaid() {
    if (!isPending) return;
    _status = PaymentStatus.paid;
    _timer?.cancel();
    notifyListeners();
  }

  void _tick() {
    if (!isPending) return;
    if (remaining == Duration.zero) {
      _status = PaymentStatus.expired;
      _timer?.cancel();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════
//  Widget pembantu (dipakai kedua halaman)
// ══════════════════════════════════════════════════════

Widget _paymentCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

Widget _infoRow(String label, Widget value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ),
        Expanded(
          flex: 3,
          child: Align(alignment: Alignment.centerRight, child: value),
        ),
      ],
    ),
  );
}

Widget _statusChip(PaymentStatus status) {
  late final String label;
  late final Color bg;
  late final Color fg;
  switch (status) {
    case PaymentStatus.pending:
      label = 'Pending';
      bg = const Color(0xFFFFF4E0);
      fg = const Color(0xFFB26A00);
    case PaymentStatus.paid:
      label = 'Berhasil';
      bg = const Color(0xFFE4F4EC);
      fg = const Color(0xFF26533C);
    case PaymentStatus.expired:
      label = 'Kedaluwarsa';
      bg = const Color(0xFFFFECEB);
      fg = const Color(0xFFC62828);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  Halaman 1 — Menunggu pembayaran (rincian & status)
// ══════════════════════════════════════════════════════

class PaymentWaitingScreen extends StatefulWidget {
  final PaymentSession session;

  const PaymentWaitingScreen({super.key, required this.session});

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> {
  @override
  void dispose() {
    widget.session.dispose();
    super.dispose();
  }

  /// Dialog saat menekan tombol kembali di pembayaran yang masih pending.
  /// Dua pilihan: keluar (pembayaran dibatalkan, kembali ke Beranda) atau
  /// tetap di halaman ini. Untuk pindah metode ada tombol terpisah
  /// "Ganti metode pembayaran".
  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECEB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 30, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar dari pembayaran?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: _ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pembayaran ini belum selesai. Jika keluar, kode pembayaran '
                'yang sekarang tidak berlaku lagi dan Anda perlu membuat '
                'top up baru.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: Color(0xFFF5C6C3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keluar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tetap di sini',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop(PaymentExit.done);
    }
  }

  /// Kembali ke pilihan metode pembayaran (pembayaran ini dibatalkan).
  void _changeMethod() => Navigator.of(context).pop(PaymentExit.changeMethod);

  void _refreshStatus() {
    final s = widget.session;
    final msg = switch (s.status) {
      PaymentStatus.paid => 'Pembayaran sudah berhasil.',
      PaymentStatus.expired => 'Batas waktu pembayaran sudah habis.',
      PaymentStatus.pending =>
        'Status masih pending. Selesaikan pembayaran sesuai instruksi.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openInstructions() async {
    final result = await Navigator.of(context).push<PaymentExit>(
      MaterialPageRoute(
        builder: (_) => PaymentInstructionScreen(session: widget.session),
      ),
    );
    // Pengguna menekan "Ganti metode pembayaran" di halaman instruksi.
    if (result == PaymentExit.changeMethod && mounted) _changeMethod();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final s = widget.session;
        return PopScope(
          canPop: !s.isPending,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            backgroundColor: _pageBg,
            appBar: AppBar(title: const Text('Top Up Kantong Amanah')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(s),
                const SizedBox(height: 16),
                _buildDetailCard(s),
                const SizedBox(height: 12),
                _buildSummaryCard(s),
                const SizedBox(height: 20),
                if (s.isPending)
                  Center(
                    child: TextButton.icon(
                      onPressed: _changeMethod,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Ganti metode pembayaran'),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: s.status == PaymentStatus.expired
                        ? ElevatedButton(
                            onPressed: _changeMethod,
                            child: const Text('Pilih Metode Lain'),
                          )
                        : ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(PaymentExit.done),
                            child: const Text('Kembali ke Beranda'),
                          ),
                  ),
                  if (s.status == PaymentStatus.expired)
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(PaymentExit.done),
                        child: const Text('Kembali ke Beranda'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(PaymentSession s) {
    late final IconData icon;
    late final Color color;
    late final String title;
    late final Widget body;

    switch (s.status) {
      case PaymentStatus.pending:
        icon = Icons.hourglass_top_rounded;
        color = AppColors.warning;
        title = 'Menunggu pembayaran';
        body = Column(
          children: [
            const Text(
              'Segera lakukan pembayaran sebelum',
              style:
                  TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(s.expiresAt),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: _ink),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _openInstructions,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lihat instruksi pembayaran',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ],
        );
      case PaymentStatus.paid:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        title = 'Pembayaran berhasil';
        body = const Text(
          'Saldo Kantong Amanah Anda sudah bertambah.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        );
      case PaymentStatus.expired:
        icon = Icons.timer_off_outlined;
        color = AppColors.error;
        title = 'Pembayaran kedaluwarsa';
        body = const Text(
          'Batas waktu pembayaran telah habis. Silakan buat top up baru.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: _ink),
        ),
        const SizedBox(height: 6),
        body,
      ],
    );
  }

  Widget _buildDetailCard(PaymentSession s) {
    const valueStyle =
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink);
    return _paymentCard(
      child: Column(
        children: [
          _infoRow('Tanggal',
              Text(_formatDate(s.createdAt), style: valueStyle)),
          _infoRow('Metode pembayaran', Text(s.method, style: valueStyle)),
          _infoRow(
              'ID transaksi', Text('#${s.referenceId}', style: valueStyle)),
          _infoRow('Status', _statusChip(s.status)),
          if (s.isPending) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _refreshStatus,
                child: const Text('Perbarui status'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PaymentSession s) {
    const valueStyle =
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink);
    return _paymentCard(
      child: Column(
        children: [
          _infoRow(
            'Total top up',
            Text(
              CurrencyUtils.formatIdr(s.amount),
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _ink),
            ),
          ),
          const Divider(height: 12),
          _infoRow('Nominal top up',
              Text(CurrencyUtils.formatIdr(s.amount), style: valueStyle)),
          _infoRow(
              'Biaya layanan', Text(CurrencyUtils.formatIdr(0), style: valueStyle)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  Halaman 2 — Instruksi pembayaran (QR / VA + hitung mundur)
// ══════════════════════════════════════════════════════

class PaymentInstructionScreen extends ConsumerStatefulWidget {
  final PaymentSession session;

  const PaymentInstructionScreen({super.key, required this.session});

  @override
  ConsumerState<PaymentInstructionScreen> createState() =>
      _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState
    extends ConsumerState<PaymentInstructionScreen> {
  bool _isProcessing = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _checkStatus() {
    switch (widget.session.status) {
      case PaymentStatus.paid:
        Navigator.of(context).pop();
      case PaymentStatus.expired:
        _snack('Batas waktu pembayaran sudah habis.');
      case PaymentStatus.pending:
        _snack('Pembayaran belum kami terima. '
            'Selesaikan pembayaran lalu cek lagi.');
    }
  }

  Future<void> _copyVa() async {
    final va = widget.session.vaNumber;
    if (va == null) return;
    await Clipboard.setData(ClipboardData(text: va));
    if (mounted) _snack('Nomor Virtual Account disalin');
  }

  /// Mode simulasi: menganggap pembayaran berhasil lalu menambah saldo.
  Future<void> _simulatePaid() async {
    final s = widget.session;
    if (_isProcessing || !s.isPending) return;

    setState(() => _isProcessing = true);
    try {
      final ok = await ref
          .read(authProvider.notifier)
          .topUpBalance(s.amount, method: s.method);
      if (!ok) {
        throw Exception('Gagal memperbarui saldo di database SQLite.');
      }

      // Tandai berhasil segera setelah saldo bertambah supaya tidak
      // bisa dibayar dua kali.
      s.markPaid();

      try {
        final user = ref.read(authProvider).user;
        await NotificationService.instance.showTopUpSuccessNotification(
          amountFormatted: CurrencyUtils.formatIdr(s.amount),
          newBalanceFormatted: CurrencyUtils.formatIdr(user?.balance ?? 0.0),
        );
      } catch (_) {
        // Notifikasi gagal tidak boleh membatalkan top up yang sudah berhasil.
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // kembali ke halaman status
    } catch (e) {
      if (mounted) _snack('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final s = widget.session;
        return Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(title: const Text('Instruksi Pembayaran')),
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildBanner(s),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    s.isQris ? _buildQrCard(s) : _buildVaCard(s),
                    const SizedBox(height: 12),
                    _paymentCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total top up',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant)),
                          Text(
                            CurrencyUtils.formatIdr(s.amount),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _ink),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _checkStatus,
                        child: const Text('Cek status pembayaran',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (s.isPending)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pop(PaymentExit.changeMethod),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: const Text('Ganti metode pembayaran'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _buildSimulationBox(s),
                    const SizedBox(height: 12),
                    _buildGuide(s),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanner(PaymentSession s) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Batas waktu pembayaran',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  _formatBannerDeadline(s.expiresAt),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            s.isPending ? _formatCountdown(s.remaining) : '00:00:00',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(PaymentSession s) {
    return _paymentCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text('Scan QR Code',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('QRIS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (s.isPending) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: QrImageView(
                data: s.qrPayload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan memakai e-wallet atau mobile banking yang mendukung QRIS',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
          ] else
            _inactivePanel(s),
        ],
      ),
    );
  }

  Widget _buildVaCard(PaymentSession s) {
    return _paymentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nomor Virtual Account ${s.bankName}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 14),
          if (s.isPending) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    _groupDigits(s.vaNumber ?? '-'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: _ink),
                  ),
                ),
                TextButton.icon(
                  onPressed: _copyVa,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Salin'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Transfer sesuai nominal ke nomor Virtual Account di atas.',
              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
            ),
          ] else
            Center(child: _inactivePanel(s)),
        ],
      ),
    );
  }

  Widget _inactivePanel(PaymentSession s) {
    final paid = s.status == PaymentStatus.paid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            paid ? Icons.check_circle_rounded : Icons.timer_off_outlined,
            size: 48,
            color: paid ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 8),
          Text(
            paid ? 'Pembayaran sudah diterima' : 'Batas waktu pembayaran habis',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationBox(PaymentSession s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE08A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: Color(0xFFB26A00)),
              SizedBox(width: 6),
              Text('Mode simulasi',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB26A00))),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Aplikasi ini belum terhubung ke payment gateway. Tekan tombol '
            'di bawah untuk mensimulasikan pembayaran yang berhasil.',
            style: TextStyle(fontSize: 11, color: Color(0xFF7A5200)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (s.isPending && !_isProcessing) ? _simulatePaid : null,
              child: _isProcessing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simulasikan Pembayaran Berhasil'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuide(PaymentSession s) {
    final steps = s.isQris
        ? const [
            'Buka aplikasi e-wallet atau mobile banking yang mendukung QRIS '
                '(GoPay, OVO, Dana, LinkAja, ShopeePay, dll).',
            'Pilih menu Scan / Bayar, lalu arahkan kamera ke QR Code di halaman ini.',
            'Pastikan nominal sudah sesuai, lalu konfirmasi pembayaran.',
            'Setelah berhasil, kembali ke KitaBantu dan tekan "Cek status pembayaran".',
          ]
        : [
            'Buka aplikasi mobile banking ${s.bankName} atau datangi ATM.',
            'Pilih menu Transfer, lalu Virtual Account.',
            'Masukkan nomor Virtual Account yang tertera di halaman ini.',
            'Periksa nominal, lalu konfirmasi dan masukkan PIN.',
            'Kembali ke KitaBantu dan tekan "Cek status pembayaran".',
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('Panduan Pembayaran',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE4F4EC),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppColors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}