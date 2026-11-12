import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/survey_point.dart';
import '../services/location_service.dart';
import '../utils/coordinate_converter.dart';

enum DrawMapLayerType {
  rbiIndonesia, // Peta Dasar RBI dari BIG
  googleSatellite, // Google Satelit
  openStreetMap, // OpenStreetMap
}

class PolygonDrawPage extends StatefulWidget {
  final LatLng initialCenter;
  final List<LatLng> initialPoints;
  final SurveyGeometryType geometryType;

  const PolygonDrawPage({
    super.key,
    required this.initialCenter,
    this.initialPoints = const [],
    this.geometryType = SurveyGeometryType.polygon,
  });

  @override
  State<PolygonDrawPage> createState() => _PolygonDrawPageState();
}

class _PolygonDrawPageState extends State<PolygonDrawPage> {
  late final List<LatLng> _points = List.of(widget.initialPoints);
  final MapController _mapController = MapController();

  DrawMapLayerType _currentLayer = DrawMapLayerType.rbiIndonesia;
  LatLng? _userLocation;
  bool _isLoadingGps = false;

  int get _minimumPoints {
    switch (widget.geometryType) {
      case SurveyGeometryType.point:
        return 1;
      case SurveyGeometryType.line:
        return 2;
      case SurveyGeometryType.polygon:
        return 3;
    }
  }

  String get _geometryLabel {
    switch (widget.geometryType) {
      case SurveyGeometryType.point:
        return 'Titik (Point)';
      case SurveyGeometryType.line:
        return 'Garis (Line)';
      case SurveyGeometryType.polygon:
        return 'Poligon (Area)';
    }
  }

  // Perhitungan luas area perkiraan menggunakan rumus Spherical Polygon / Shoelace
  double _calculateAreaMeters(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    const double radius = 6378137.0; // WGS84 Earth radius in meters
    double area = 0.0;
    final int len = points.length;

    for (int i = 0; i < len; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % len];
      final lat1 = p1.latitude * math.pi / 180.0;
      final lat2 = p2.latitude * math.pi / 180.0;
      final lon1 = p1.longitude * math.pi / 180.0;
      final lon2 = p2.longitude * math.pi / 180.0;
      area += (lon2 - lon1) * (2.0 + math.sin(lat1) + math.sin(lat2));
    }
    area = area.abs() * radius * radius / 4.0;
    return area;
  }

  // Perhitungan panjang keliling / jarak garis
  double _calculateLengthMeters(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    const Distance distance = Distance();
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }
    if (widget.geometryType == SurveyGeometryType.polygon && points.length >= 3) {
      total += distance.as(LengthUnit.Meter, points.last, points.first);
    }
    return total;
  }

  void _handleTap(LatLng point) {
    setState(() {
      if (widget.geometryType == SurveyGeometryType.point) {
        // Untuk mode Point: ketukan baru menggantikan titik sebelumnya
        _points
          ..clear()
          ..add(point);
      } else {
        _points.add(point);
      }
    });
  }

  // Reset rotasi kompas tegak lurus ke Utara (0°)
  void _resetNorth() {
    _mapController.rotate(0.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧭 Peta diarahkan tegak lurus ke Utara (0.0°)'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  // Mengambil dan memusatkan kamera ke lokasi GPS terkini
  Future<void> _recenterToCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _userLocation = latLng;
          _isLoadingGps = false;
        });
        _mapController.move(latLng, 17.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Lokasi terkini ditemukan: (${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})'),
            backgroundColor: Colors.blueAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal membaca GPS: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Mengganti Base Map secara berurutan
  void _cycleBaseMap() {
    setState(() {
      switch (_currentLayer) {
        case DrawMapLayerType.rbiIndonesia:
          _currentLayer = DrawMapLayerType.googleSatellite;
          break;
        case DrawMapLayerType.googleSatellite:
          _currentLayer = DrawMapLayerType.openStreetMap;
          break;
        case DrawMapLayerType.openStreetMap:
          _currentLayer = DrawMapLayerType.rbiIndonesia;
          break;
      }
    });
    String name = 'Peta Dasar RBI (BIG)';
    if (_currentLayer == DrawMapLayerType.googleSatellite) name = 'Google Satelit';
    if (_currentLayer == DrawMapLayerType.openStreetMap) name = 'OpenStreetMap';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗺️ Peta Dasar diubah: $name'),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _zoomIn() {
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, z + 1);
  }

  void _zoomOut() {
    final z = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, z - 1);
  }

  void _finishDrawing() {
    if (_points.length < _minimumPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.geometryType == SurveyGeometryType.point
                ? 'Ketuk peta untuk menentukan satu titik lokasi.'
                : 'Minimal $_minimumPoints titik untuk ${widget.geometryType == SurveyGeometryType.line ? "garis" : "poligon bidang"}.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    Navigator.of(context).pop(List<LatLng>.unmodifiable(_points));
  }

  @override
  Widget build(BuildContext context) {
    final isPoint = widget.geometryType == SurveyGeometryType.point;
    final isPolygon = widget.geometryType == SurveyGeometryType.polygon;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final areaMeters = isPolygon ? _calculateAreaMeters(_points) : 0.0;
    final perimeterMeters = _calculateLengthMeters(_points);

    // Konfigurasi URL Base Map
    String tileUrl;
    String layerName;
    switch (_currentLayer) {
      case DrawMapLayerType.rbiIndonesia:
        tileUrl = 'https://geoservices.big.go.id/rbi/rest/services/BASEMAP/Rupabumi_Indonesia/MapServer/tile/{z}/{y}/{x}';
        layerName = 'Peta Dasar RBI (BIG)';
        break;
      case DrawMapLayerType.googleSatellite:
        tileUrl = 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
        layerName = 'Google Satelit';
        break;
      case DrawMapLayerType.openStreetMap:
        tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
        layerName = 'OpenStreetMap';
        break;
    }

    final polygons = isPolygon && _points.length >= 3
        ? [
            Polygon(
              points: _points,
              color: Colors.blue.withValues(alpha: 0.35),
              borderColor: const Color(0xFF1D4ED8),
              borderStrokeWidth: 2.5,
            ),
          ]
        : <Polygon>[];

    final polylines = _points.length >= 2
        ? [
            Polyline(
              points: _points,
              color: const Color(0xFF2563EB),
              strokeWidth: 3.5,
            ),
          ]
        : <Polyline>[];

    final markers = <Marker>[];

    // Marker Lokasi Terkini Pengguna (GPS) jika ada
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
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
      );
    }

    if (isPoint && _points.isNotEmpty) {
      // Pin penanda untuk Titik Tunggal
      final pt = _points.first;
      markers.add(
        Marker(
          point: pt,
          width: 50,
          height: 50,
          alignment: Alignment.topCenter,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.redAccent,
                size: 42,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Marker simpul berangka untuk Garis dan Poligon
      for (var index = 0; index < _points.length; index++) {
        markers.add(
          Marker(
            point: _points[index],
            width: 32,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                color: index == 0 ? Colors.green.shade600 : const Color(0xFF1E40AF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isPoint ? 'Pilih Lokasi Titik' : 'Digitasi $_geometryLabel'),
        actions: [
          IconButton(
            onPressed: _cycleBaseMap,
            tooltip: 'Ganti Peta Dasar ($layerName)',
            icon: const Icon(Icons.layers_outlined, color: Colors.amberAccent),
          ),
          if (!isPoint)
            IconButton(
              onPressed: _points.isEmpty ? null : () => setState(() => _points.removeLast()),
              tooltip: 'Batalkan titik terakhir',
              icon: const Icon(Icons.undo),
            ),
          IconButton(
            onPressed: _points.isEmpty ? null : () => setState(_points.clear),
            tooltip: isPoint ? 'Hapus pilihan titik' : 'Hapus semua titik',
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: _points.length >= _minimumPoints ? _finishDrawing : null,
            tooltip: 'Simpan',
            icon: const Icon(Icons.check, color: Colors.greenAccent),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _points.isNotEmpty ? _points.first : widget.initialCenter,
              initialZoom: 17,
              onTap: (_, point) => _handleTap(point),
            ),
            children: [
              TileLayer(
                key: ValueKey(_currentLayer),
                urlTemplate: tileUrl,
                userAgentPackageName: 'id.ac.unhas.mobilegis',
              ),
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // Floating Info Bar Pengukuran Real-Time di Atas
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Card(
              elevation: 4,
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.blue.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isPoint
                          ? Icons.place
                          : (isPolygon ? Icons.pentagon_outlined : Icons.polyline),
                      color: isPoint ? Colors.redAccent : const Color(0xFF2563EB),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: isPoint
                          ? (_points.isNotEmpty
                              ? Builder(builder: (context) {
                                  final pt = _points.first;
                                  final utm = CoordinateConverter.latLonToUtm(pt.latitude, pt.longitude);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Lat: ${pt.latitude.toStringAsFixed(6)}°, Lon: ${pt.longitude.toStringAsFixed(6)}°',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                      Text(
                                        'UTM ${utm.zoneString}: X=${utm.easting.toStringAsFixed(1)}m, Y=${utm.northing.toStringAsFixed(1)}m',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                })
                              : const Text(
                                  'Ketuk pada peta untuk memilih lokasi titik',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                ))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isPolygon
                                      ? (areaMeters >= 10000
                                          ? 'Luas: ${(areaMeters / 10000).toStringAsFixed(2)} Ha (${areaMeters.toStringAsFixed(0)} m²)'
                                          : 'Luas: ${areaMeters.toStringAsFixed(1)} m²')
                                      : (perimeterMeters >= 1000
                                          ? 'Panjang: ${(perimeterMeters / 1000).toStringAsFixed(2)} km'
                                          : 'Panjang: ${perimeterMeters.toStringAsFixed(1)} m'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'Simpul: ${_points.length} Titik • ${isPolygon ? "Keliling: ${perimeterMeters.toStringAsFixed(1)} m" : "Garis Terhubung"}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Cluster Tombol Navigasi Peta di Sisi Kanan (Arah Utara, Layer, Zoom, Lokasi Terkini)
          Positioned(
            right: 14,
            top: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Tombol Reset Arah Utara (Kompas)
                FloatingActionButton.small(
                  heroTag: 'btnDrawResetNorth',
                  onPressed: _resetNorth,
                  backgroundColor: Colors.white,
                  tooltip: 'Arahkan Peta ke Utara (0°)',
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, color: Colors.redAccent, size: 16),
                      Text(
                        'U',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Tombol Pengubah Base Map
                FloatingActionButton.small(
                  heroTag: 'btnDrawCycleLayer',
                  onPressed: _cycleBaseMap,
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.amber,
                  tooltip: 'Ganti Base Map ($layerName)',
                  child: const Icon(Icons.layers_outlined),
                ),
                const SizedBox(height: 8),

                // 3. Tombol Zoom In & Zoom Out
                FloatingActionButton.small(
                  heroTag: 'btnDrawZoomIn',
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                FloatingActionButton.small(
                  heroTag: 'btnDrawZoomOut',
                  onPressed: _zoomOut,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black87),
                ),
                const SizedBox(height: 10),

                // 4. Tombol Lokasi Terkini (GPS)
                FloatingActionButton(
                  heroTag: 'btnDrawRecenter',
                  onPressed: _isLoadingGps ? null : _recenterToCurrentLocation,
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  tooltip: 'Pusatkan ke Lokasi GPS Terkini',
                  child: _isLoadingGps
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Badge Informasi Base Map Aktif di Kiri Bawah
          Positioned(
            left: 14,
            bottom: 84,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map, size: 13, color: Colors.amberAccent),
                  const SizedBox(width: 5),
                  Text(
                    layerName,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Tombol Selesai Floating di Bawah
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ElevatedButton.icon(
              onPressed: _points.length >= _minimumPoints ? _finishDrawing : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPoint ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              icon: Icon(isPoint ? Icons.check_circle : Icons.done_all),
              label: Text(
                isPoint
                    ? (_points.isNotEmpty
                        ? 'Gunakan Titik Koordinat Ini'
                        : 'Ketuk peta untuk menentukan titik lokasi')
                    : (_points.length >= _minimumPoints
                        ? 'Selesai Digitasi (${_points.length} Simpul)'
                        : 'Ketuk peta untuk menambah titik (min $_minimumPoints)'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
