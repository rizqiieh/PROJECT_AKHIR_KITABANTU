import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Layanan Notifikasi Lokal (RF-009).
///
/// Memicu notifikasi instan saat donasi berhasil dicatat ke ledger
/// dan pengingat kampanye donasi.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inisialisasi plugin notifikasi Android & iOS.
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Callback saat user tap notifikasi
      },
    );

    // Minta izin notifikasi di Android 13+ (API 33+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  /// Notifikasi saat simulasi donasi berhasil dicatat ke Ledger (RF-009).
  Future<void> showDonationSuccessNotification({
    required String campaignTitle,
    required String amountFormatted,
    required String referenceCode,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'donation_channel',
      'Donasi & Transaksi',
      channelDescription: 'Pemberitahuan bukti pencatatan transaksi donasi ke Ledger',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id,
      '🎉 Donasi Berhasil Dicatat ke Ledger!',
      'Alhamdulillah, donasi $amountFormatted untuk "$campaignTitle" berhasil diverifikasi dengan Ref: $referenceCode.',
      notificationDetails,
    );
  }

  /// Notifikasi pengingat kampanye donasi (RF-009).
  Future<void> showCampaignReminderNotification({
    required String campaignTitle,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Pengingat Kampanye',
      channelDescription: 'Pengingat kampanye yang Anda simpan/jadwalkan',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id,
      '🔔 Pengingat Kampanye',
      'Mari luangkan sedikit rezeki untuk "$campaignTitle". Bantuan Anda sangat berarti!',
      notificationDetails,
    );
  }

  /// Notifikasi saat simulasi Top Up saldo berhasil.
  Future<void> showTopUpSuccessNotification({
    required String amountFormatted,
    required String newBalanceFormatted,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'wallet_channel',
      'Kantong Amanah & Saldo',
      channelDescription: 'Pemberitahuan perubahan saldo dan top-up kantong amanah',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id,
      'Top Up Saldo Berhasil! 🎉',
      'Saldo $amountFormatted telah ditambahkan ke Kantong Amanah. Saldo saat ini: $newBalanceFormatted.',
      notificationDetails,
    );
  }
}
