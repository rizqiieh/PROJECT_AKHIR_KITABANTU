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
///  1 — Saran      : Formulir kesan & saran mata kuliah.
///  2 — Profil     : Data akun, toggle biometrik, bookmark, riwayat zakat.
///  3 — Logout     : Mencegat onTap → AlertDialog konfirmasi keluar.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  /// Mencegah dialog logout muncul dobel kalau tab ditekan berkali-kali.
  bool _isLogoutDialogOpen = false;

  /// Mencegah proses logout berjalan dua kali.
  bool _isLoggingOut = false;

  /// Daftar layar untuk tab 0, 1, dan 2.
  /// Tab 3 (Logout) tidak memiliki layar — hanya memicu dialog.
  final List<Widget> _screens = const [
    BerandaScreen(),
    SaranKesanScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Efek geser horizontal (dari kanan ke kiri)
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ));

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF264E36),
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Saran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    // Tab Logout (index 3): tampilkan dialog, jangan ganti halaman.
    if (index == 3) {
      _showLogoutDialog();
      return;
    }

    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  /// Dialog konfirmasi logout (Bab 4.3).
  /// Menghapus sesi dan navigasi ke LoginScreen.
  Future<void> _showLogoutDialog() async {
    if (_isLogoutDialogOpen || _isLoggingOut) return;
    _isLogoutDialogOpen = true;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout, color: AppColors.error, size: 40),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    _isLogoutDialogOpen = false;
    if (shouldLogout != true || !mounted) return;

    _isLoggingOut = true;
    try {
      await ref.read(authProvider.notifier).logout();
    } catch (e) {
      // Kalau penghapusan sesi gagal (mis. secure storage error), pengguna
      // tetap diarahkan ke Login supaya tombol tidak terasa "mati".
      debugPrint('Logout: gagal menghapus sesi → $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}