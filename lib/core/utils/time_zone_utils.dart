import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Utilitas konversi waktu akurat lintas zona (RF-006 & Bab 12).
///
/// Mendukung 4 zona waktu:
/// - WIB  (Asia/Jakarta, UTC+7)
/// - WITA (Asia/Makassar, UTC+8)
/// - WIT  (Asia/Jayapura, UTC+9)
/// - London (Europe/London, UTC+0 / UTC+1 dengan penyesuaian DST otomatis)
class TimeZoneUtils {
  TimeZoneUtils._();

  static bool _initialized = false;

  /// Inisialisasi basis data zona waktu IANA.
  static void initialize() {
    if (!_initialized) {
      tz_data.initializeTimeZones();
      _initialized = true;
    }
  }

  /// Mengonversi [dateTime] ke zona waktu tertentu.
  /// Mendukung zone name: 'WIB', 'WITA', 'WIT', 'London' (atau lokasi tz IANA).
  static DateTime convertToZone(DateTime dateTime, String zone) {
    initialize();

    final utcTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final tzLocationName = _resolveTzLocation(zone);
    final location = tz.getLocation(tzLocationName);
    final tzDateTime = tz.TZDateTime.from(utcTime, location);

    return tzDateTime;
  }

  /// Format DateTime ke teks rapi berdasarkan zona (misal: "21 Okt 2026, 14:30 WIB").
  static String formatInZone(DateTime dateTime, String zone,
      {String pattern = 'dd MMM yyyy, HH:mm'}) {
    initialize();
    final converted = convertToZone(dateTime, zone);
    final formatter = DateFormat(pattern, 'id_ID');
    try {
      return '${formatter.format(converted)} ${_zoneLabel(zone)}';
    } catch (_) {
      // Fallback tanpa id_ID locale jika belum di-initialize
      final fallbackFormatter = DateFormat(pattern);
      return '${fallbackFormatter.format(converted)} ${_zoneLabel(zone)}';
    }
  }

  /// Mengambil representasi serempak di 4 zona waktu sekaligus.
  static Map<String, String> formatAllFourZones(DateTime dateTime) {
    return {
      'WIB': formatInZone(dateTime, 'WIB'),
      'WITA': formatInZone(dateTime, 'WITA'),
      'WIT': formatInZone(dateTime, 'WIT'),
      'London': formatInZone(dateTime, 'London'),
    };
  }

  static String _resolveTzLocation(String zone) {
    switch (zone.toUpperCase()) {
      case 'WIB':
        return 'Asia/Jakarta';
      case 'WITA':
        return 'Asia/Makassar';
      case 'WIT':
        return 'Asia/Jayapura';
      case 'LONDON':
        return 'Europe/London';
      default:
        return zone;
    }
  }

  static String _zoneLabel(String zone) {
    switch (zone.toUpperCase()) {
      case 'WIB':
        return 'WIB';
      case 'WITA':
        return 'WITA';
      case 'WIT':
        return 'WIT';
      case 'LONDON':
        return 'London';
      default:
        return zone;
    }
  }
}
