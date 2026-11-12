import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Layanan Notifikasi Lokal (RF-009).
///
/// Memicu notifikasi instan saat donasi berhasil dicatat ke ledger,
/// pengingat kampanye donasi, top-up, dan pembayaran zakat.
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

    final initSettings = const InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
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

    final notificationDetails = const NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id: id,
      title: '🎉 Donasi Berhasil Dicatat ke Ledger!',
      body: 'Alhamdulillah, donasi $amountFormatted untuk "$campaignTitle" berhasil diverifikasi dengan Ref: $referenceCode.',
      notificationDetails: notificationDetails,
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

    final notificationDetails = const NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id: id,
      title: '🔔 Pengingat Kampanye',
      body: 'Mari luangkan sedikit rezeki untuk "$campaignTitle". Bantuan Anda sangat berarti!',
      notificationDetails: notificationDetails,
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

    final notificationDetails = const NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id: id,
      title: 'Top Up Saldo Berhasil! 🎉',
      body: 'Saldo $amountFormatted telah ditambahkan ke Kantong Amanah. Saldo saat ini: $newBalanceFormatted.',
      notificationDetails: notificationDetails,
    );
  }

  /// Notifikasi saat pembayaran Zakat berhasil.
  Future<void> showZakatSuccessNotification({
    required String jenisZakat,
    required String amountFormatted,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'zakat_channel',
      'Pembayaran Zakat',
      channelDescription: 'Pemberitahuan pemotongan saldo untuk Zakat',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );

    final notificationDetails = const NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      id: id,
      title: 'Alhamdulillah, Zakat Tertunaikan 🤲',
      body: '$jenisZakat sebesar $amountFormatted telah berhasil dipotong dari Kantong Amanah.',
      notificationDetails: notificationDetails,
    );
  }
}