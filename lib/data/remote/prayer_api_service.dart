import 'dart:convert';
import 'package:http/http.dart' as http;

class PrayerApiService {
  PrayerApiService._();
  static final PrayerApiService instance = PrayerApiService._();

  // 1. Ambil berdasarkan GPS Lokal
  Future? fetchPrayerTimes(double lat, double lng) async {
    final url = 'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lng&method=20';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data']['timings'];
      }
    } catch (_) {}
    return null;
  }

  // 2. Ambil berdasarkan Nama Kota (Untuk Perbandingan 5 Zona)
  Future<dynamic> fetchPrayerTimesByCity(String city, String country) async {
    final url = 'https://api.aladhan.com/v1/timingsByCity?city=$city&country=$country&method=20';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data']['timings'];
      }
    } catch (_) {}
    return null;
  }
}