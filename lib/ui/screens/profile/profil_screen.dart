import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/providers/campaign_provider.dart';
import 'package:kitabantu/ui/screens/profile/bookmarks_screen.dart';
import 'package:kitabantu/ui/screens/profile/zakat_history_screen.dart';

/// Layar Profil (Tab 2 — RF-002 & RF-003).
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final bookmarkCount = bookmarksAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Avatar Bergambar (RF-003) ──
            GestureDetector(
              onTap: () => _showAvatarOptions(context, ref),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.secondary,
                    backgroundImage: user?.avatarPath != null
                        ? FileImage(File(user!.avatarPath!))
                        : null,
                    child: user?.avatarPath == null
                        ? const Icon(Icons.person,
                            size: 50, color: AppColors.onPrimary)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: AppColors.onPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Nama & Username ──
            Text(
              user?.fullName ?? 'Nama Pengguna',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user?.username ?? 'username'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),

            // ── Badge info akun ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Terdaftar sejak ${_formatDate(user?.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Menu Pengaturan & Data Lokal (SQLite) ──
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // Toggle Biometrik (RF-002)
                  SwitchListTile(
                    title: const Text('Login Biometrik'),
                    subtitle: Text(
                      user?.biometricEnabled == true
                          ? 'Sidik jari / wajah aktif'
                          : 'Gunakan sidik jari / wajah untuk masuk',
                    ),
                    secondary: Icon(
                      Icons.fingerprint,
                      color: user?.biometricEnabled == true
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    value: user?.biometricEnabled ?? false,
                    activeTrackColor: AppColors.secondary,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return null;
                    }),
                    onChanged: (value) =>
                        _toggleBiometric(context, ref, value),
                  ),
                  const Divider(height: 1),

                  // Kampanye Tersimpan (SQLite RF-004)
                  ListTile(
                    leading: const Icon(Icons.bookmark,
                        color: AppColors.primary),
                    title: const Text('Kampanye Tersimpan (SQLite)'),
                    subtitle: Text('$bookmarkCount kampanye favorit'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const BookmarksScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),

                  // Riwayat Hitung Zakat (SQLite RF-008)
                  ListTile(
                    leading: const Icon(Icons.history,
                        color: AppColors.primary),
                    title: const Text('Riwayat Hitung Zakat (SQLite)'),
                    subtitle: const Text('Lihat kalkulasi zakat tersimpan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ZakatHistoryScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Informasi Enkripsi & Keamanan ──
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keamanan Akun Terenkripsi',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Password di-hash dengan SHA-256 + 32-char salt unik di SQLite lokal.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(
      BuildContext context, WidgetRef ref, bool enable) async {
    final success =
        await ref.read(authProvider.notifier).toggleBiometric(enable);

    if (!context.mounted) return;

    if (!success && enable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Gagal mengaktifkan biometrik. Pastikan sensor biometrik tersedia dan sidik jari telah didaftarkan di perangkat.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enable
              ? 'Login biometrik aktif ✓'
              : 'Login biometrik dinonaktifkan'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
