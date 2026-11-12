import 'dart:convert';
import 'package:latlong2/latlong.dart';

enum SurveyGeometryType { point, line, polygon }

class SurveyFeature {
  final SurveyGeometryType type;
  final List<LatLng> points;

  const SurveyFeature({
    required this.type,
    required this.points,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'points': points.map((p) => [p.latitude, p.longitude]).toList(),
    };
  }

  factory SurveyFeature.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? 'point';
    final type = SurveyGeometryType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeName.toLowerCase(),
      orElse: () => SurveyGeometryType.point,
    );
    final rawPoints = map['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((item) {
      if (item is List && item.length >= 2) {
        return LatLng((item[0] as num).toDouble(), (item[1] as num).toDouble());
      } else if (item is Map) {
        return LatLng(
          (item['lat'] as num).toDouble(),
          (item['lng'] as num).toDouble(),
        );
      }
      return const LatLng(0, 0);
    }).toList();

    return SurveyFeature(type: type, points: points);
  }
}

class SurveyPoint {
  final int? id;
  final String nama;
  final String kategori;
  final String? keterangan;
  final double latitude;
  final double longitude;
  final String? fotoPath;
  final String waktu;
  final String tipeGeometri; // 'Point', 'Line', atau 'Polygon'
  final String? koordinatList; // JSON String list titik jika Line/Polygon: [{"lat":..,"lng":..}]

  SurveyPoint({
    this.id,
    required this.nama,
    required this.kategori,
    this.keterangan,
    required this.latitude,
    required this.longitude,
    this.fotoPath,
    required this.waktu,
    this.tipeGeometri = 'Point',
    this.koordinatList,
  });

  // Kompatibilitas atribut tugas kelompok
  String get namaSurveyor => nama;
  String get nim => 'V126241003';
  bool get kondisiRusak => false;

  SurveyGeometryType get geometryType {
    switch (tipeGeometri.toLowerCase()) {
      case 'line':
        return SurveyGeometryType.line;
      case 'polygon':
        return SurveyGeometryType.polygon;
      default:
        return SurveyGeometryType.point;
    }
  }

  // Konversi objek SurveyPoint ke Map untuk disimpan di database SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'keterangan': keterangan,
      'latitude': latitude,
      'longitude': longitude,
      'fotoPath': fotoPath,
      'waktu': waktu,
      'tipeGeometri': tipeGeometri,
      'koordinatList': koordinatList,
    };
  }

  // Membuat objek SurveyPoint dari data Map database SQLite
  factory SurveyPoint.fromMap(Map<String, dynamic> map) {
    return SurveyPoint(
      id: map['id'] as int?,
      nama: map['nama'] as String? ?? map['nama_surveyor'] as String? ?? '',
      kategori: map['kategori'] as String? ?? 'Umum',
      keterangan: map['keterangan'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      fotoPath: (map['fotoPath'] as String?) ?? (map['foto_path'] as String?),
      waktu: map['waktu'] as String? ?? '',
      tipeGeometri: (map['tipeGeometri'] as String?) ??
          (map['geometry_type'] as String?) ??
          'Point',
      koordinatList: (map['koordinatList'] as String?) ??
          (map['polygon_json'] as String?) ??
          (map['geometry_json'] as String?),
    );
  }

  // Helper untuk membaca parsed coordinates
  List<Map<String, double>> get parsedCoordinates {
    if (koordinatList == null || koordinatList!.isEmpty || koordinatList == '[]') {
      return [
        {'lat': latitude, 'lng': longitude}
      ];
    }
    try {
      final dynamic decoded = jsonDecode(koordinatList!);
      if (decoded is List) {
        return decoded.map((e) {
          if (e is Map) {
            return {
              'lat': (e['lat'] as num).toDouble(),
              'lng': (e['lng'] as num).toDouble(),
            };
          } else if (e is List && e.length >= 2) {
            return {
              'lat': (e[0] as num).toDouble(),
              'lng': (e[1] as num).toDouble(),
            };
          }
          return {'lat': latitude, 'lng': longitude};
        }).toList();
      }
    } catch (_) {}
    return [
      {'lat': latitude, 'lng': longitude}
    ];
  }

  // Helper daftar LatLng untuk FlutterMap
  List<LatLng> get latLngPoints {
    return parsedCoordinates
        .map((c) => LatLng(c['lat']!, c['lng']!))
        .toList();
  }

  // Helper geometry features untuk polygon dan line rendering
  List<SurveyFeature> get geometryFeatures {
    if (geometryType == SurveyGeometryType.point) {
      return [
        SurveyFeature(
          type: SurveyGeometryType.point,
          points: [LatLng(latitude, longitude)],
        )
      ];
    }
    return [
      SurveyFeature(
        type: geometryType,
        points: latLngPoints,
      )
    ];
  }
}
