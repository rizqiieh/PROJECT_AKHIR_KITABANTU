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
late final PageController _pageController;
  /// Daftar layar untuk tab 0, 1, dan 2.
  /// Tab 3 (Logout) tidak memiliki layar — hanya memicu dialog.
  final List<Widget> _screens = const [
    BerandaScreen(),
    SaranKesanScreen(),
    ProfilScreen(),
    
  ];
@override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
     body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Membuat efek animasi geser secara horizontal (dari kanan ke kiri)
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0), // Mulai dari sisi kanan layar
            end: Offset.zero,              // Berakhir tepat di tengah
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,       // Membuat pergerakannya lebih natural
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
=======
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Menonaktifkan swipe agar tidak sengaja tergeser
        children: _screens,
>>>>>>> 4d81ed6136d5f102840a5554939dd727900ebcdf
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
  // Jika menekan tab Logout (index 3), tampilkan dialog dan jangan ganti halaman
  if (index == 3) {
    _showLogoutDialog(); // atau method logout bawaanmu
    return;
  }

  setState(() {
    _currentIndex = index;
  });

  // BARIS INI YANG WAJIB ADA AGAR HALAMAN BENAR-BENAR BERPINDAH:
  _pageController.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOutCubic,
  );
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
