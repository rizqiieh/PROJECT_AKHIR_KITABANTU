import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/data/local/database_helper.dart';
import 'package:kitabantu/data/local/secure_storage_service.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/ui/screens/auth/login_screen.dart';
import 'package:kitabantu/ui/screens/home/main_shell.dart';
import 'onboarding_screen.dart';

/// Splash Screen — pengecekan sesi aktif & session timeout (Bab 6 §1).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Tampilkan splash minimal 1.5 detik
    await Future.delayed(const Duration(milliseconds: 1500));
    await ref.read(authProvider.notifier).checkSession();

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      _navigateTo(const MainShell());
    } else {
      if (authState.errorMessage != null && authState.errorMessage!.isNotEmpty) {
        _navigateTo(LoginScreen(sessionExpiredMessage: authState.errorMessage));
      } else {
        // Cek apakah pengguna sudah pernah melihat pengantar atau sudah ada akun terdaftar
        final hasCompletedOnboarding =
            await SecureStorageService.instance.hasCompletedOnboarding();
        final hasRegisteredUsers = await DatabaseHelper.instance.hasAnyUser();

        if (hasCompletedOnboarding || hasRegisteredUsers) {
          _navigateTo(const LoginScreen());
        } else {
          _navigateTo(const OnboardingScreen());
        }
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Image.asset(
                    'assets/images/LogoKitaBantu.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'KitaBantu',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crowdfunding Sosial & Zakat Digital',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
