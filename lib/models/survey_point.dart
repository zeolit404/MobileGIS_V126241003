import 'dart:convert';

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
      nama: map['nama'] as String? ?? '',
      kategori: map['kategori'] as String? ?? 'Umum',
      keterangan: map['keterangan'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      fotoPath: map['fotoPath'] as String?,
      waktu: map['waktu'] as String? ?? '',
      tipeGeometri: map['tipeGeometri'] as String? ?? 'Point',
      koordinatList: map['koordinatList'] as String?,
    );
  }

  // Helper untuk membaca parsed coordinates
  List<Map<String, double>> get parsedCoordinates {
    if (koordinatList == null || koordinatList!.isEmpty) {
      return [
        {'lat': latitude, 'lng': longitude}
      ];
    }
    try {
      final List<dynamic> decoded = jsonDecode(koordinatList!);
      return decoded.map((e) => {
        'lat': (e['lat'] as num).toDouble(),
        'lng': (e['lng'] as num).toDouble(),
      }).toList();
    } catch (_) {
      return [
        {'lat': latitude, 'lng': longitude}
      ];
    }
  }
}
