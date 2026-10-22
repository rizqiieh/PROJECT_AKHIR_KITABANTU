import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/time_zone_utils.dart';
import 'data/remote/supabase_service.dart';
import 'ui/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  // Inisialisasi basis data zona waktu (WIB, WITA, WIT, London)
  TimeZoneUtils.initialize();

  // Inisialisasi Supabase Online Service (RF-004)
  await SupabaseService.instance.initialize();

  // Inisialisasi notifikasi lokal perangkat (RF-009)
  await NotificationService.instance.initialize();

  runApp(
    // ProviderScope diperlukan oleh flutter_riverpod (Bab 3 — State Management)
    const ProviderScope(child: KitaBantuApp()),
  );
}

class KitaBantuApp extends StatelessWidget {
  const KitaBantuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitaBantu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
