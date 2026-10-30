class SurveyPoint {
  final int? id;
  final String nama;
  final String kategori;
  final String? keterangan;
  final double latitude;
  final double longitude;
  final String? fotoPath;
  final String waktu;

  SurveyPoint({
    this.id,
    required this.nama,
    required this.kategori,
    this.keterangan,
    required this.latitude,
    required this.longitude,
    this.fotoPath,
    required this.waktu,
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
    };
  }

  // Membuat objek SurveyPoint dari data Map database SQLite
  factory SurveyPoint.fromMap(Map<String, dynamic> map) {
    return SurveyPoint(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      kategori: map['kategori'] as String,
      keterangan: map['keterangan'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      fotoPath: map['fotoPath'] as String?,
      waktu: map['waktu'] as String,
    );
  }
}
