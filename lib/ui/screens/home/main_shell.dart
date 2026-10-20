import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/ui/screens/auth/login_screen.dart';
import 'beranda_screen.dart';
import '../profile/profil_screen.dart';
import '../profile/saran_kesan_screen.dart';

/// Kerangka navigasi utama dengan BottomNavigationBar 4 tab (Bab 4.3 & Bab 6).
///
/// Tab:
///  0 — Beranda   : Dashboard utama, grid fitur, daftar kampanye.
///  1 — Profil     : Data akun, toggle biometrik, bookmark, riwayat zakat.
///  2 — Saran      : Formulir kesan & saran mata kuliah.
///  3 — Logout     : Mencegat onTap → AlertDialog konfirmasi keluar.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  /// Daftar layar untuk tab 0, 1, dan 2.
  /// Tab 3 (Logout) tidak memiliki layar — hanya memicu dialog.
  final List<Widget> _screens = const [
    BerandaScreen(),
    ProfilScreen(),
    SaranKesanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Saran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_outlined),
            activeIcon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == 3) {
      _showLogoutDialog();
      return;
    }
    setState(() => _currentIndex = index);
  }

  /// Dialog konfirmasi logout (Bab 4.3).
  /// Menghapus sesi dan navigasi ke LoginScreen.
  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout, color: AppColors.error, size: 40),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authProvider.notifier).logout();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
