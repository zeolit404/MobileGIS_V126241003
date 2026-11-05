import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../db/database_helper.dart';
import '../models/survey_point.dart';
import '../services/location_service.dart';
import '../utils/platform_image_helper.dart';

enum MapLayerType {
  rbiIndonesia, // Peta Dasar RBI dari BIG (Default)
  googleSatellite,
  openStreetMap,
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLatLng;
  StreamSubscription<Position>? _positionSub;

  // Koordinat Kampus Unhas Tamalanrea
  static const LatLng _defaultCenter = LatLng(-5.1357, 119.4886);

  MapLayerType _currentLayer = MapLayerType.rbiIndonesia;
  List<SurveyPoint> _savedPoints = [];
  SurveyPoint? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _loadSavedPoints();
    _startListeningLocation();
  }

  Future<void> _loadSavedPoints() async {
    try {
      final points = await DatabaseHelper.instance.getAllSurveys();
      if (mounted) setState(() => _savedPoints = points);
    } catch (_) {}
  }

  void _startListeningLocation() {
    _positionSub = LocationService.getPositionStream().listen((position) {
      if (mounted) {
        setState(() {
          _currentLatLng = LatLng(position.latitude, position.longitude);
        });
      }
    });

    LocationService.getCurrentPosition()
        .then((position) {
          final latLng = LatLng(position.latitude, position.longitude);
          if (mounted) {
            setState(() => _currentLatLng = latLng);
            _mapController.move(latLng, 16);
          }
        })
        .catchError((_) {});
  }

  void _recenterLocation() {
    final target = _currentLatLng ?? _defaultCenter;
    _mapController.move(target, 16);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _resetToNorth() {
    _mapController.rotate(0.0);
  }

  void _cycleLayer() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;

    setState(() {
      if (_currentLayer == MapLayerType.rbiIndonesia) {
        _currentLayer = MapLayerType.googleSatellite;
      } else if (_currentLayer == MapLayerType.googleSatellite) {
        _currentLayer = MapLayerType.openStreetMap;
      } else {
        _currentLayer = MapLayerType.rbiIndonesia;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(currentCenter, currentZoom);
    });
  }

  // Pilih titik tanpa mengubah zoom dan posisi kamera
  void _pilihTitik(SurveyPoint point) {
    setState(() {
      _selectedPoint = point;
    });
  }

  Widget _buildPopupImage(String? fotoPath) {
    if (fotoPath == null || fotoPath.isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.place, color: Colors.white, size: 30),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: PlatformImageHelper.buildImage(
        fotoPath,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.broken_image, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String tileUrl;
    String layerName;
    switch (_currentLayer) {
      case MapLayerType.rbiIndonesia:
        tileUrl = 'https://geoservices.big.go.id/rbi/rest/services/BASEMAP/Rupabumi_Indonesia/MapServer/tile/{z}/{y}/{x}';
        layerName = 'Peta Dasar RBI (BIG)';
        break;
      case MapLayerType.googleSatellite:
        tileUrl = 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
        layerName = 'Google Satelit';
        break;
      case MapLayerType.openStreetMap:
        tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        layerName = 'OpenStreetMap';
        break;
    }

    // 1. Polylines (Garis dari survei bertipe Line)
    final polylines = <Polyline>[];
    // 2. Polygons (Area dari survei bertipe Polygon)
    final polygons = <Polygon>[];

    for (final p in _savedPoints) {
      final coords = p.parsedCoordinates.map((e) => LatLng(e['lat']!, e['lng']!)).toList();
      if (p.tipeGeometri == 'Line' && coords.length >= 2) {
        polylines.add(
          Polyline(
            points: coords,
            strokeWidth: 4.0,
            color: Colors.blueAccent.shade700,
          ),
        );
      } else if (p.tipeGeometri == 'Polygon' && coords.length >= 3) {
        polygons.add(
          Polygon(
            points: coords,
            color: Colors.amber.withValues(alpha: 0.35),
            borderColor: Colors.amber.shade900,
            borderStrokeWidth: 2.5,
          ),
        );
      }
    }

    // 3. Markers
    final markers = <Marker>[
      // Marker Referensi Kampus Unhas
      Marker(
        point: _defaultCenter,
        width: 36,
        height: 36,
        child: const Icon(Icons.school, color: Color(0xFF1E293B), size: 30),
      ),

      // Marker Titik-titik Hasil Survei (Kuning Emas)
      ..._savedPoints.map((point) {
        final pos = LatLng(point.latitude, point.longitude);
        final isSelected = _selectedPoint?.id == point.id;
        IconData geomIcon = Icons.location_on;
        if (point.tipeGeometri == 'Line') geomIcon = Icons.polyline;
        if (point.tipeGeometri == 'Polygon') geomIcon = Icons.pentagon_outlined;

        return Marker(
          point: pos,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _pilihTitik(point), // Tidak reset zoom / melompat
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.amberAccent : Colors.amber.shade700,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Icon(geomIcon, color: Colors.white, size: 24),
            ),
          ),
        );
      }),

      // Marker Posisi Pengguna (GPS)
      if (_currentLatLng != null)
        Marker(
          point: _currentLatLng!,
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.my_location, color: Colors.blueAccent, size: 28),
            ),
          ),
        ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng ?? _defaultCenter,
              initialZoom: 16,
              onTap: (tapPosition, point) {
                if (_selectedPoint != null) {
                  setState(() => _selectedPoint = null);
                }
              },
            ),
            children: [
              TileLayer(
                key: ValueKey(_currentLayer),
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.praktekmobilegis.praktek_mobile_gis',
              ),
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // POPUP ATAS YANG LEBIH RAPI & ELEGAN (Material 3 Card)
          if (_selectedPoint != null)
            Positioned(
              top: 16,
              left: 14,
              right: 14,
              child: Card(
                elevation: 8,
                shadowColor: Colors.black45,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.shade700, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPopupImage(_selectedPoint!.fotoPath),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedPoint!.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _selectedPoint!.tipeGeometri,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Kategori: ${_selectedPoint!.kategori}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Koordinat: ${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                            if (_selectedPoint!.keterangan != null && _selectedPoint!.keterangan!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _selectedPoint!.keterangan!,
                                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black45, size: 20),
                        onPressed: () => setState(() => _selectedPoint = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Tombol Kontrol Peta Samping Kanan
          Positioned(
            right: 14,
            bottom: 30,
            child: Column(
              children: [
                // Tombol Reset Arah Utara (North Arrow)
                FloatingActionButton.small(
                  heroTag: 'btnResetNorth',
                  onPressed: _resetToNorth,
                  backgroundColor: Colors.white,
                  tooltip: 'Arahkan Peta ke Utara',
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, color: Colors.redAccent, size: 16),
                      Text(
                        'U',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                FloatingActionButton.small(
                  heroTag: 'btnRefreshSaved',
                  onPressed: _loadSavedPoints,
                  backgroundColor: Colors.white,
                  tooltip: 'Segarkan Titik Survei',
                  child: const Icon(Icons.refresh, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                FloatingActionButton.small(
                  heroTag: 'btnCycleLayer',
                  onPressed: _cycleLayer,
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.amber,
                  tooltip: 'Ganti Layer Peta',
                  child: const Icon(Icons.layers_outlined),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'btnZoomIn',
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                FloatingActionButton.small(
                  heroTag: 'btnZoomOut',
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'btnRecenter',
                  onPressed: _recenterLocation,
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Bar Info Layer & Koordinat Kiri Bawah
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.map, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    layerName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentLatLng != null
                        ? '${_currentLatLng!.latitude.toStringAsFixed(4)}, ${_currentLatLng!.longitude.toStringAsFixed(4)}'
                        : 'GPS Mencari...',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
