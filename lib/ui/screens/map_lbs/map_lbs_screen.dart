import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/data/models/campaign_model.dart';
import 'package:kitabantu/data/repositories/campaign_repository.dart';
import 'package:kitabantu/ui/screens/campaign/campaign_detail_screen.dart';

/// Halaman Peta LBS Panti Asuhan & Bencana Terdekat (Bab 6 §6 — RF-005).
class MapLbsScreen extends StatefulWidget {
  const MapLbsScreen({super.key});

  @override
  State<MapLbsScreen> createState() => _MapLbsScreenState();
}

class _MapLbsScreenState extends State<MapLbsScreen> {
  final MapController _mapController = MapController();

  // Titik tengah default: Malioboro, Yogyakarta
  static const LatLng _defaultLocation = LatLng(-7.7956, 110.3695);

  LatLng _currentPosition = _defaultLocation;
  bool _isLoadingLocation = true;
  List<CampaignModel> _campaigns = [];
  Map<String, double> _distancesInKm = {};
  CampaignModel? _selectedCampaign;

  @override
  void initState() {
    super.initState();
    _loadCampaignsAndLocation();
  }
  void _resetNorthAndRecenter() {
    // Mengembalikan peta ke posisi pengguna saat ini dan reset rotasi ke 0 (Utara)
    _mapController.moveAndRotate(
      _currentPosition,
      _mapController.camera.zoom,
      0.0, // Sudut rotasi 0 derajat (North up)
    );
  }

  Future<void> _loadCampaignsAndLocation() async {
    final list = await CampaignRepository.instance.getCampaigns();
    _campaigns = list;

    // Ambil posisi GPS pengguna via geolocator
    await _getUserLocation();

    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _calculateDistances(_defaultLocation);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _calculateDistances(_defaultLocation);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _calculateDistances(_defaultLocation);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final userLatLng = LatLng(pos.latitude, pos.longitude);
      _currentPosition = userLatLng;
      _calculateDistances(userLatLng);
      _mapController.move(userLatLng, 13.0);
    } catch (_) {
      _calculateDistances(_defaultLocation);
    }
  }

  void _calculateDistances(LatLng from) {
    final map = <String, double>{};
    for (var c in _campaigns) {
      final meters = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        c.latitude,
        c.longitude,
      );
      map[c.id] = meters / 1000.0; // km
    }
    _distancesInKm = map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta LBS Sekitar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Lokasi Saya',
            onPressed: () {
              setState(() => _isLoadingLocation = true);
              _getUserLocation().then((_) {
                if (mounted) setState(() => _isLoadingLocation = false);
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Peta OpenStreetMap (flutter_map) ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 12.0,
              onTap: (tapPosition, point) {
                if (_selectedCampaign != null) {
                  setState(() => _selectedCampaign = null);
                }
              },
            ),
            
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.kitabantu',
              ),
              MarkerLayer(
                markers: [
                  // Marker Lokasi Pengguna (Biru)
                  Marker(
                    point: _currentPosition,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Marker Kampanye (Hijau / Merah)
                  ..._campaigns.map((c) {
                    final isSelected = _selectedCampaign?.id == c.id;
                    final isBencana = c.category == 'Bencana';
                    final color =
                        isBencana ? AppColors.error : AppColors.primary;

                    return Marker(
                      point: LatLng(c.latitude, c.longitude),
                      width: isSelected ? 48 : 38,
                      height: isSelected ? 48 : 38,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedCampaign = c);
                          _mapController.move(
                            LatLng(c.latitude, c.longitude),
                            14.0,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            isBencana
                                ? Icons.warning_amber_rounded
                                : Icons.volunteer_activism,
                            color: Colors.white,
                            size: isSelected ? 24 : 18,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2F6533),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tooltip: 'Arahkan ke Utara & Pusatkan Lokasi',
              onPressed: _resetNorthAndRecenter,
              child: const Icon(Icons.navigation, size: 22), // Ikon jarum kompas
            ),
          ),
          // ── Loading Indicator GPS ──
          if (_isLoadingLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Menyelaraskan koordinat GPS perangkat...',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Kartu Ringkas saat Marker Ditekan (Bab 6 §6) ──
          if (_selectedCampaign != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedCampaign!.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_distancesInKm[_selectedCampaign!.id] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Jarak: ${_distancesInKm[_selectedCampaign!.id]!.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedCampaign!.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCampaign!.locationLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CampaignDetailScreen(
                                  campaign: _selectedCampaign!,
                                ),
                              ),
                            );
                          },
                          child: const Text('Buka Detail Kampanye'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
