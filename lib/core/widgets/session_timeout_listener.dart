import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitabantu/data/local/secure_storage_service.dart';
import 'package:kitabantu/main.dart';
import 'package:kitabantu/providers/auth_provider.dart';
import 'package:kitabantu/ui/screens/auth/login_screen.dart';

/// Pemantau Inactivity & App Lifecycle Timeout (1 Menit).
///
/// 1. Jika aplikasi dibuka kembali setelah ditutup < 1 menit → sesi tetap aktif.
/// 2. Jika aplikasi ditutup/berada di background >= 1 menit → auto-logout ke LoginScreen.
/// 3. Jika aplikasi tetap terbuka tetapi tidak ada interaksi sentuhan >= 1 menit → auto-logout.
class SessionTimeoutListener extends ConsumerStatefulWidget {
  final Widget child;
  const SessionTimeoutListener({super.key, required this.child});

  @override
  ConsumerState<SessionTimeoutListener> createState() =>
      _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends ConsumerState<SessionTimeoutListener>
    with WidgetsBindingObserver {
  Timer? _idleTimer;
  final _secure = SecureStorageService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final isAuthenticated =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (!isAuthenticated) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Aplikasi sedang diminimalkan atau ditutup → catat waktu terakhir aktif
      _secure.updateLastActive();
    } else if (state == AppLifecycleState.resumed) {
      // Aplikasi dibuka kembali → periksa apakah sudah lewat 1 menit
      _checkTimeoutOnResume();
    }
  }

  Future<void> _checkTimeoutOnResume() async {
    final isAuthenticated =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (!isAuthenticated) return;

    final isExpired = await _secure.isSessionExpired();
    if (isExpired) {
      await _triggerLogout();
    } else {
      // Sesi masih valid (< 1 menit) → perbarui aktivitas dan reset timer
      await _secure.updateLastActive();
      _resetIdleTimer();
    }
  }

  void _onUserActivity() {
    final isAuthenticated =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (!isAuthenticated) return;

    _secure.updateLastActive();
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    final isAuthenticated =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (!isAuthenticated) return;

    _idleTimer = Timer(
      const Duration(seconds: SecureStorageService.sessionTimeoutSeconds),
      () {
        _triggerLogout();
      },
    );
  }

  Future<void> _triggerLogout() async {
    _idleTimer?.cancel();
    final isAuthenticated =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (!isAuthenticated) return;

    await ref.read(authProvider.notifier).logoutDueToInactivity();

    // Navigasi ke LoginScreen via Global NavigatorKey
    KitaBantuApp.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          sessionExpiredMessage:
              'Sesi Anda telah berakhir karena tidak ada aktivitas selama 1 menit.',
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        _resetIdleTimer();
      } else if (next.status != AuthStatus.authenticated) {
        _idleTimer?.cancel();
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      child: widget.child,
    );
  }
}
