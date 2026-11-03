import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../db/database_helper.dart';
import '../models/survey_point.dart';
import '../services/location_service.dart';

enum MapLayerType {
  rbiIndonesia, // Peta Dasar RBI dari BIG (Default tugas Arief)
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

  // Fitur Arief: Default Peta Dasar RBI (BIG)
  MapLayerType _currentLayer = MapLayerType.rbiIndonesia;

  // Fitur Database: Menampilkan titik survei tersimpan
  List<SurveyPoint> _savedPoints = [];

  // Fitur Raehan: Titik yang sedang dipilih untuk popup di ATAS
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

  void _cycleLayer() {
    setState(() {
      if (_currentLayer == MapLayerType.rbiIndonesia) {
        _currentLayer = MapLayerType.googleSatellite;
      } else if (_currentLayer == MapLayerType.googleSatellite) {
        _currentLayer = MapLayerType.openStreetMap;
      } else {
        _currentLayer = MapLayerType.rbiIndonesia;
      }
    });
  }

  Widget _buildPopupImage(String? fotoPath) {
    if (fotoPath == null || fotoPath.isEmpty) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.place, color: Colors.white, size: 28),
      );
    }

    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fotoPath,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.broken_image, color: Colors.white),
          ),
        ),
      );
    } else {
      final file = File(fotoPath);
      if (!file.existsSync()) {
        return Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.place, color: Colors.white, size: 28),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menentukan URL Tile sesuai layer
    String tileUrl;
    String layerName;
    switch (_currentLayer) {
      case MapLayerType.rbiIndonesia:
        // Peta Dasar RBI BIG (format ArcGIS REST: {z}/{y}/{x})
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

    final markers = <Marker>[
      // 1. Marker Referensi Kampus Unhas
      Marker(
        point: _defaultCenter,
        width: 36,
        height: 36,
        child: const Icon(Icons.school, color: Color(0xFF1E293B), size: 30),
      ),

      // 2. Fitur Raehan: Titik-titik survei dari database berwarna KUNING EMAS
      ..._savedPoints.map((point) {
        final pos = LatLng(point.latitude, point.longitude);
        final isSelected = _selectedPoint?.id == point.id;
        return Marker(
          point: pos,
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedPoint = point);
              _mapController.move(pos, 16.5);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.amberAccent : Colors.amber.shade700, // TITIK KUNING
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.location_on, color: Colors.white, size: 24),
            ),
          ),
        );
      }),

      // 3. Marker Lokasi Pengguna (GPS)
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
              onTap: (_, p) {
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
              MarkerLayer(markers: markers),
            ],
          ),

          // FITUR RAEHAN: POPUP DI BAGIAN ATAS LAYAR (TOP SHEET CARD) - AMAN DARI CRASH WEB
          if (_selectedPoint != null)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Card(
                elevation: 6,
                color: const Color(0xFF0F172A), // Dark Navy yang bersih
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.amber, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview Foto (Aman di Web & Android)
                      _buildPopupImage(_selectedPoint!.fotoPath),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedPoint!.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Kategori: ${_selectedPoint!.kategori}',
                              style: const TextStyle(fontSize: 12, color: Colors.amber),
                            ),
                            Text(
                              '(${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)})',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                            if (_selectedPoint!.keterangan != null &&
                                _selectedPoint!.keterangan!.isNotEmpty)
                              Text(
                                _selectedPoint!.keterangan!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.white60),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 18),
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
            bottom: 50,
            child: Column(
              children: [
                // Tombol Switcher Layer (RBI / Satelit / OSM)
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
                  backgroundColor: const Color(0xFF2563EB), // Royal Blue
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
