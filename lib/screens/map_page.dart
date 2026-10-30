import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';

enum MapLayerType {
  openStreetMap,
  googleSatellite,
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

  static const LatLng _defaultCenter = LatLng(-5.1357, 119.4886);

  // Pilihan Layer Aktif (Default: OpenStreetMap)
  MapLayerType _currentLayer = MapLayerType.openStreetMap;

  @override
  void initState() {
    super.initState();
    _startListeningLocation();
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
            setState(() {
              _currentLatLng = latLng;
            });
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

  void _toggleLayer() {
    setState(() {
      _currentLayer = _currentLayer == MapLayerType.openStreetMap
          ? MapLayerType.googleSatellite
          : MapLayerType.openStreetMap;
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sesuai modul: hanya marker referensi dan marker GPS pengguna
    final markers = <Marker>[
      Marker(
        point: _defaultCenter,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40,
        ),
      ),
      if (_currentLatLng != null)
        Marker(
          point: _currentLatLng!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 36,
          ),
        ),
    ];

    // Menentukan URL basemap berdasarkan layer yang dipilih
    final isSatellite = _currentLayer == MapLayerType.googleSatellite;
    final tileUrl = isSatellite
        ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Chip(
              avatar: Icon(
                _currentLatLng != null ? Icons.gps_fixed : Icons.gps_not_fixed,
                size: 16,
                color: _currentLatLng != null ? Colors.white : Colors.amber.shade900,
              ),
              label: Text(
                _currentLatLng != null ? 'GPS Aktif' : 'Mencari GPS',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentLatLng != null ? Colors.white : Colors.amber.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: _currentLatLng != null ? Colors.green.shade600 : Colors.amber.shade100,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng ?? _defaultCenter,
              initialZoom: 16,
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

          // Tombol Kontrol Peta Samping Kanan (Ganti Layer, Zoom in, Zoom out, My Location)
          Positioned(
            right: 16,
            bottom: 60,
            child: Column(
              children: [
                // Tombol Ganti Layer (Satelit / OSM)
                FloatingActionButton.small(
                  heroTag: 'btnToggleLayer',
                  onPressed: _toggleLayer,
                  backgroundColor: Colors.white,
                  tooltip: isSatellite ? 'Mode Standar (OSM)' : 'Mode Satelit Google',
                  child: Icon(
                    isSatellite ? Icons.map_outlined : Icons.satellite_alt_outlined,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 10),
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
                  backgroundColor: Colors.green.shade700,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),

          // Floating Bar Koordinat Bawah (Minimalis)
          Positioned(
            left: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSatellite ? Colors.black87 : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 16,
                    color: isSatellite ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currentLatLng != null
                        ? 'Lat: ${_currentLatLng!.latitude.toStringAsFixed(5)}  |  Lon: ${_currentLatLng!.longitude.toStringAsFixed(5)}'
                        : 'Lat: ${_defaultCenter.latitude.toStringAsFixed(5)}  |  Lon: ${_defaultCenter.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSatellite ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSatellite ? Colors.blueGrey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isSatellite ? 'Satelit' : 'OSM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSatellite ? Colors.lightBlueAccent : Colors.black54,
                      ),
                    ),
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
