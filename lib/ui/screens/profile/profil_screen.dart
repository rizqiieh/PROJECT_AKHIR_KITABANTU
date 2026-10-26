import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/providers/campaign_provider.dart';
import 'package:kitabantu/ui/screens/profile/bookmarks_screen.dart';
import 'package:kitabantu/ui/screens/profile/zakat_history_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Warna tambahan khusus halaman ini (nuansa mint sesuai desain Stitch)
const _ink = Color(0xFF1B3A2A); // teks gelap kehijauan
const _mint = Color(0xFFDDF3E5); // latar ikon / chip
const _mintSoft = Color(0xFFF1FBF5); // latar kotak statistik
const _mintBorder = Color(0xFFD5EBDD); // garis tepi kartu

/// Layar Profil (Tab 2 — RF-002 & RF-003) dengan desain baru.
/// Layar Profil (Tab 2 - RF-002 & RF-003) dengan desain baru.
class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricSetting();
  }

  Future<void> _loadBiometricSetting() async {
    final value = await _storage.read(key: 'biometric_enabled');
    if (mounted) {
      setState(() {
        _isBiometricEnabled = value == 'true';
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    // 1. Panggil provider agar Supabase/Auth Service mengaktifkan sesi biometrik
    final success = await ref.read(authProvider.notifier).toggleBiometric(value);

    if (!mounted) return;

    // Jika perangkat menolak / sidik jari belum terdaftar di HP
    if (!success && value) {
      setState(() {
        _isBiometricEnabled = false;
      });
      await _storage.write(key: 'biometric_enabled', value: 'false');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mengaktifkan biometrik. Pastikan sensor tersedia dan sidik jari terdaftar di perangkat.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 2. Simpan status switch dan perbarui UI jika berhasil
    setState(() {
      _isBiometricEnabled = value;
    });
    await _storage.write(key: 'biometric_enabled', value: value.toString());
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Login biometrik berhasil diaktifkan'
              : 'Login biometrik dinonaktifkan',
        ),
        backgroundColor: const Color(0xFF2F6533),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Catatan: di ConsumerState parameter 'WidgetRef ref' tidak perlu ditulis lagi 
    // karena 'ref' sudah otomatis tersedia bawaan dari ConsumerState.
    final user = ref.watch(authProvider).user;
    final bookmarkCount = ref.watch(bookmarksProvider).value?.length ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FDF7), Color(0xFFE2F5E9)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                _buildTitleRow(),
                const SizedBox(height: 16),
                _buildProfileCard(
                  context,
                  ref,
                  fullName: user?.fullName ?? 'Nama Pengguna',
                  username: user?.username ?? 'username',
                  createdAt: user?.createdAt,
                  avatarPath: user?.avatarPath,
                  biometricEnabled: user?.biometricEnabled ?? false,
                ),
                const SizedBox(height: 16),
                _buildMenuCard(context, bookmarkCount),
                const SizedBox(height: 16),
                _buildSecurityCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Header (logo + lonceng) ─────────────────────────
  Widget _buildTopBar() => Row(
        children: [
          const Icon(Icons.volunteer_activism,
              color: AppColors.primary, size: 28),
          const SizedBox(width: 8),
          const Text(
            'KitaBantu',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: _ink),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {}, // TODO: arahkan ke halaman notifikasi
            icon: const Icon(Icons.notifications_none, color: _ink),
          ),
        ],
      );

  // ───────────────────────── Judul + chip Terverifikasi ──────────────────────
  Widget _buildTitleRow() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Profil Pengguna',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: _ink),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _mintBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Terverifikasi',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
              ],
            ),
          ),
        ],
      );

  // ───────────────────────── Kartu profil utama ──────────────────────────────
  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref, {
    required String fullName,
    required String username,
    required String? createdAt,
    required String? avatarPath,
    required bool biometricEnabled,
  }) =>
      _card(
        child: Column(
          children: [
            // Avatar + identitas
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(context, ref, avatarPath),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username • Sejak ${_formatDate(createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _mint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Donatur Peduli Aktif',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _ink)),
                            SizedBox(width: 4),
                            Icon(Icons.star,
                                size: 12, color: Color(0xFFF2A900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: _mintBorder),
            ),

            // Dua kotak statistik
            // TODO: ganti nilai di bawah dengan data asli dari provider donasi
            Row(
              children: [
                _statBox('Total Infaq & Donasi', 'Rp 0'),
                const SizedBox(width: 12),
                _statBox('Aksi Gotong Royong', '0 Program'),
              ],
            ),
            const SizedBox(height: 16),

            // Baris biometrik (RF-002)
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fingerprint,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aktifkan Login Biometrik',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      const SizedBox(height: 2),
                      Text(
                        _isBiometricEnabled
                       ? 'Sidik jari aktif'
                         : 'Sidik jari / Face ID saat membuka aplikasi',
                         style: const TextStyle(
                         fontSize: 11.5,
                         color: AppColors.onSurfaceVariant,
                         ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: _isBiometricEnabled,
                   activeTrackColor: const Color(0xFF2F6533),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                 return Colors.white;
                   }
                   return null;
                    }),
                  onChanged: (val) => _toggleBiometric(val),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _buildAvatar(BuildContext context, WidgetRef ref, String? path) =>
      GestureDetector(
        onTap: () => _showAvatarOptions(context, ref),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _mintBorder, width: 2),
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.secondary,
                backgroundImage: path != null ? FileImage(File(path)) : null,
                child: path == null
                    ? const Icon(Icons.person,
                        size: 34, color: AppColors.onPrimary)
                    : null,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _statBox(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: _mintSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _mintBorder),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );

  // ───────────────── Menu data lokal (SQLite RF-004 & RF-008) ────────────────
  Widget _buildMenuCard(BuildContext context, int bookmarkCount) => _card(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          children: [
            _menuTile(
              icon: Icons.bookmark,
              title: 'Kampanye Tersimpan (SQLite)',
              subtitle: '$bookmarkCount kampanye favorit',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarksScreen()),
              ),
            ),
            const Divider(height: 1, indent: 12, endIndent: 12, color: _mintBorder),
            _menuTile(
              icon: Icons.history,
              title: 'Riwayat Hitung Zakat (SQLite)',
              subtitle: 'Lihat kalkulasi zakat tersimpan',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ZakatHistoryScreen()),
              ),
            ),
          ],
        ),
      );

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      );

  // ───────────────────────── Info keamanan ───────────────────────────────────
  Widget _buildSecurityCard() => _card(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keamanan Akun Terenkripsi',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  SizedBox(height: 2),
                  Text(
                    'Password di-hash dengan SHA-256 + 32-char salt unik di SQLite lokal.',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ───────────────────────── Kartu putih generik ─────────────────────────────
  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _mintBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x143A6B4F),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );

  // ───────────────────────── Logika (tidak berubah) ──────────────────────────
  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Foto Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.account_circle, color: AppColors.primary),
                title: const Text('Gunakan Avatar Bawaan'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(authProvider.notifier).updateAvatar(null);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Hapus Foto Profil'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(authProvider.notifier).updateAvatar(null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }
}