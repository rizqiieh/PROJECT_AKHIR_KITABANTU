import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kitabantu/core/constants/app_colors.dart';
import 'package:kitabantu/data/models/campaign_model.dart';
import 'package:kitabantu/data/repositories/campaign_repository.dart';
import 'package:kitabantu/ui/screens/campaign/campaign_detail_screen.dart';

// Warna tambahan khusus halaman ini (nuansa mint sesuai desain Stitch)
const _ink = Color(0xFF1B3A2A);
const _mint = Color(0xFFDDF3E5);
const _mintBorder = Color(0xFFD5EBDD);

// ─────────────────────────────────────────────────────────────────────────────
// TODO: sesuaikan dua fungsi ini dengan field di CampaignModel Anda
// (misal: collectedAmount / targetAmount dan donorCount).
// Saat ini nilainya masih placeholder supaya kode pasti bisa di-compile.
// ─────────────────────────────────────────────────────────────────────────────
double _progressOf(CampaignModel c) => 0.0; // rentang 0.0 - 1.0
int _donorsOf(CampaignModel c) => 0;

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

  // State tampilan baru
  bool _showMap = true; // true = Tampilan Peta, false = Daftar Lokasi
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCampaignsAndLocation();
  }

  // ───────────────────────── Logika data & GPS (tidak berubah) ───────────────
  Future<void> _loadCampaignsAndLocation() async {
    final list = await CampaignRepository.instance.getCampaigns();
    _campaigns = list;

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

  void _refreshLocation() {
    setState(() => _isLoadingLocation = true);
    _getUserLocation().then((_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    });
  }

  // ───────────────────────── Helper ──────────────────────────────────────────
  List<CampaignModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _campaigns;
    return _campaigns
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.locationLabel.toLowerCase().contains(q))
        .toList();
  }

  bool _isBencana(CampaignModel c) => c.category == 'Bencana';

  IconData _iconFor(CampaignModel c) =>
      _isBencana(c) ? Icons.warning_amber_rounded : Icons.volunteer_activism;

  void _selectCampaign(CampaignModel c) {
    setState(() {
      _selectedCampaign = c;
      _showMap = true;
    });
    _mapController.move(LatLng(c.latitude, c.longitude), 14.0);
  }

  /// Tombol "directions": tampilkan posisi Anda & lokasi kampanye sekaligus.
  void _showBothPoints(CampaignModel c) {
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [_currentPosition, LatLng(c.latitude, c.longitude)],
        padding: const EdgeInsets.fromLTRB(60, 60, 60, 280),
      ),
    );
  }

  // ───────────────────────── BUILD ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FDF7), Color(0xFFE2F5E9)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              if (_searching) _buildSearchField(),
              _buildToggle(),
              Expanded(
                child: IndexedStack(
                  index: _showMap ? 0 : 1,
                  sizing: StackFit.expand,
                  children: [_buildMapView(), _buildListView()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Header, pencarian, toggle ───────────────────────
  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            if (Navigator.canPop(context))
              IconButton(
                icon: const Icon(Icons.arrow_back, color: _ink),
                onPressed: () => Navigator.maybePop(context),
              )
            else
              const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peta Bantuan Sekitar',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  SizedBox(height: 2),
                  Text('Kampanye terdekat dari lokasi Anda',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_searching ? Icons.close : Icons.search,
                  color: _ink),
              onPressed: () => setState(() {
                _searching = !_searching;
                if (!_searching) _query = '';
              }),
            ),
          ],
        ),
      );

  Widget _buildSearchField() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Cari nama atau lokasi kampanye...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _mintBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _mintBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      );

  Widget _buildToggle() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _segment('Tampilan Peta', Icons.map, true),
              _segment('Daftar Lokasi', Icons.format_list_bulleted, false),
            ],
          ),
        ),
      );

  Widget _segment(String label, IconData icon, bool isMap) {
    final selected = _showMap == isMap;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showMap = isMap),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : _ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Tampilan Peta ───────────────────────────────────
  Widget _buildMapView() {
    final campaigns = _filtered;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition,
            initialZoom: 12.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
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
                _userMarker(),
                ...campaigns.map(_campaignMarker),
              ],
            ),
          ],
        ),

        // Tombol kompas & lokasi saya (kanan atas)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _mapButton(Icons.explore_outlined, 'Arahkan ke Utara',
                  () => _mapController.rotate(0.0)),
              const SizedBox(height: 10),
              _mapButton(Icons.my_location, 'Lokasi Saya', _refreshLocation),
            ],
          ),
        ),

        // Indikator loading GPS
        if (_isLoadingLocation)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 6),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Menyelaraskan GPS...',
                      style: TextStyle(fontSize: 11.5, color: _ink)),
                ],
              ),
            ),
          ),

        // Kartu kampanye terpilih
        if (_selectedCampaign != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildSelectedCard(_selectedCampaign!),
          ),
      ],
    );
  }

  Widget _mapButton(IconData icon, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          elevation: 3,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: _ink),
            ),
          ),
        ),
      );

  // Marker posisi pengguna: titik hijau + label "Lokasi Anda"
  Marker _userMarker() => Marker(
        point: _currentPosition,
        width: 120,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
            Positioned(
              bottom: 0,
              child: _markerLabel('Lokasi Anda', false),
            ),
          ],
        ),
      );

  // Marker kampanye: label nama + pin bulat bergaris putih
  Marker _campaignMarker(CampaignModel c) {
    final isSelected = _selectedCampaign?.id == c.id;
    final color = _isBencana(c) ? AppColors.error : AppColors.primary;
    final d = isSelected ? 44.0 : 34.0;

    return Marker(
      point: LatLng(c.latitude, c.longitude),
      width: 120,
      height: isSelected ? 92 : 80,
      // topCenter: seluruh marker berada DI ATAS titik koordinat,
      // sehingga ujung pin tepat di lokasi kampanye.
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _selectCampaign(c),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _markerLabel(c.title, isSelected),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: d,
                height: d,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDark : color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), blurRadius: 6),
                  ],
                ),
                child: Icon(_iconFor(c),
                    color: Colors.white, size: isSelected ? 24 : 18),
              ),
              Transform.translate(
                offset: const Offset(0, -5),
                child: Icon(Icons.arrow_drop_down,
                    size: 20,
                    color: isSelected ? AppColors.primaryDark : color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _markerLabel(String text, bool selected) => Container(
        constraints: const BoxConstraints(maxWidth: 116),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 4),
          ],
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _ink,
          ),
        ),
      );

  // ───────────────────────── Kartu kampanye terpilih ─────────────────────────
  Widget _buildSelectedCard(CampaignModel c) {
    final dist = _distancesInKm[c.id];
    final progress = _progressOf(c).clamp(0.0, 1.0);

    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip jarak + chip kategori
          Row(
            children: [
              if (dist != null)
                Flexible(
                  child: _chip(
                    '${dist.toStringAsFixed(1)} km dari lokasi Anda',
                    icon: Icons.near_me,
                  ),
                ),
              const Spacer(),
              _chip(c.category),
            ],
          ),
          const SizedBox(height: 12),

          // Judul + ikon verified
          Row(
            children: [
              Expanded(
                child: Text(
                  c.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: AppColors.primary, size: 22),
            ],
          ),
          const SizedBox(height: 4),

          // Alamat
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  c.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress donasi
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _mint,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Terkumpul ${(progress * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
              Text('${_donorsOf(c)} Donatur Gotong Royong',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),

          // Tombol aksi
          Row(
            children: [
              Tooltip(
                message: 'Lihat posisi Anda & lokasi kampanye',
                child: OutlinedButton(
                  onPressed: () => _showBothPoints(c),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 48),
                    side: const BorderSide(color: _mintBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child:
                      const Icon(Icons.directions, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CampaignDetailScreen(campaign: c),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lihat Kampanye',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {IconData? icon}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _mint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: _ink),
              ),
            ),
          ],
        ),
      );

  // ───────────────────────── Daftar Lokasi ───────────────────────────────────
  Widget _buildListView() {
    final items = [..._filtered]..sort((a, b) =>
        (_distancesInKm[a.id] ?? double.infinity)
            .compareTo(_distancesInKm[b.id] ?? double.infinity));

    if (items.isEmpty) {
      return const Center(
        child: Text('Tidak ada lokasi ditemukan',
            style: TextStyle(color: AppColors.onSurfaceVariant)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final c = items[i];
        final dist = _distancesInKm[c.id];
        final color = _isBencana(c) ? AppColors.error : AppColors.primary;

        return GestureDetector(
          onTap: () => _selectCampaign(c),
          child: _card(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_iconFor(c), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      const SizedBox(height: 2),
                      Text(c.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      _chip(c.category),
                    ],
                  ),
                ),
                if (dist != null) ...[
                  const SizedBox(width: 8),
                  Text('${dist.toStringAsFixed(1)} km',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────── Kartu putih generik ─────────────────────────────
  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _mintBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x143A6B4F),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );
}
