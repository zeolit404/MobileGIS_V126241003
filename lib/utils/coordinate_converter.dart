import 'dart:math' as math;

/// Model hasil kalkulasi UTM
class UtmCoordinate {
  final double easting; // X (meter)
  final double northing; // Y (meter)
  final int zone; // Zona 1 - 60
  final String hemisphere; // 'N' atau 'S'

  const UtmCoordinate({
    required this.easting,
    required this.northing,
    required this.zone,
    required this.hemisphere,
  });

  String get zoneString => '$zone$hemisphere';

  String get formatted =>
      'Zona $zone$hemisphere | X: ${easting.toStringAsFixed(1)} m, Y: ${northing.toStringAsFixed(1)} m';
}

/// Konverter Geodesi Presisi antara Datum WGS 84 dan Proyeksi UTM
class CoordinateConverter {
  // Konstanta Ellipsoid WGS 84
  static const double _a = 6378137.0; // Sumbu semi-mayor (meter)
  static const double _f = 1.0 / 298.257223563; // Penggepengan (flattening)
  static const double _k0 = 0.9996; // Faktor skala meridian tengah UTM
  static const double _e2 = 2 * _f - _f * _f; // Eksentrisitas kuadrat
  static const double _ePrime2 = _e2 / (1.0 - _e2); // Eksentrisitas kedua kuadrat

  /// Mengonversi WGS 84 (Latitude, Longitude) ke Koordinat Proyeksi UTM (Easting, Northing, Zone)
  static UtmCoordinate latLonToUtm(double lat, double lon) {
    final latRad = lat * (math.pi / 180.0);
    final lonRad = lon * (math.pi / 180.0);

    // Hitung Zona UTM (1-60)
    int zone = ((lon + 180.0) / 6.0).floor() + 1;
    if (zone < 1) zone = 1;
    if (zone > 60) zone = 60;

    final hemisphere = lat >= 0.0 ? 'N' : 'S';

    // Bujur Meridian Tengah (Central Meridian)
    final lonOrigin = (zone - 1) * 6 - 180 + 3;
    final lonOriginRad = lonOrigin * (math.pi / 180.0);

    final sinLat = math.sin(latRad);
    final cosLat = math.cos(latRad);
    final tanLat = math.tan(latRad);

    final N = _a / math.sqrt(1.0 - _e2 * sinLat * sinLat);
    final T = tanLat * tanLat;
    final C = _ePrime2 * cosLat * cosLat;
    final A = cosLat * (lonRad - lonOriginRad);

    // Panjang busur meridian dari ekuator
    final M = _a * (
      (1.0 - _e2 / 4.0 - 3.0 * _e2 * _e2 / 64.0 - 5.0 * _e2 * _e2 * _e2 / 256.0) * latRad
      - (3.0 * _e2 / 8.0 + 3.0 * _e2 * _e2 / 32.0 + 45.0 * _e2 * _e2 * _e2 / 1024.0) * math.sin(2.0 * latRad)
      + (15.0 * _e2 * _e2 / 256.0 + 45.0 * _e2 * _e2 * _e2 / 1024.0) * math.sin(4.0 * latRad)
      - (35.0 * _e2 * _e2 * _e2 / 3072.0) * math.sin(6.0 * latRad)
    );

    // Easting (X) dengan False Easting 500,000 meter
    final easting = (_k0 * N * (A + (1.0 - T + C) * A * A * A / 6.0
        + (5.0 - 18.0 * T + T * T + 72.0 * C - 58.0 * _ePrime2) * A * A * A * A * A / 120.0)) + 500000.0;

    // Northing (Y)
    double northing = _k0 * (M + N * tanLat * (A * A / 2.0
        + (5.0 - T + 9.0 * C + 4.0 * C * C) * A * A * A * A / 24.0
        + (61.0 - 58.0 * T + T * T + 600.0 * C - 330.0 * _ePrime2) * A * A * A * A * A * A / 720.0));

    if (lat < 0.0) {
      northing += 10000000.0; // False Northing 10,000,000 m untuk Belahan Bumi Selatan (South)
    }

    return UtmCoordinate(
      easting: easting,
      northing: northing,
      zone: zone,
      hemisphere: hemisphere,
    );
  }

  /// Mengonversi Koordinat UTM (Easting, Northing, Zone, Hemisphere) kembali ke WGS 84 (Latitude, Longitude)
  static Map<String, double> utmToLatLon({
    required double easting,
    required double northing,
    required int zone,
    required String hemisphere,
  }) {
    final x = easting - 500000.0; // Kurangi False Easting
    double y = northing;
    if (hemisphere.toUpperCase() == 'S') {
      y -= 10000000.0; // Kurangi False Northing untuk belahan selatan
    }

    final lonOrigin = (zone - 1) * 6 - 180 + 3;
    final lonOriginRad = lonOrigin * (math.pi / 180.0);

    final e1 = (1.0 - math.sqrt(1.0 - _e2)) / (1.0 + math.sqrt(1.0 - _e2));
    final M = y / _k0;
    final mu = M / (_a * (1.0 - _e2 / 4.0 - 3.0 * _e2 * _e2 / 64.0 - 5.0 * _e2 * _e2 * _e2 / 256.0));

    final phi1Rad = mu
        + (3.0 * e1 / 2.0 - 27.0 * e1 * e1 * e1 / 32.0) * math.sin(2.0 * mu)
        + (21.0 * e1 * e1 / 16.0 - 55.0 * e1 * e1 * e1 * e1 / 32.0) * math.sin(4.0 * mu)
        + (151.0 * e1 * e1 * e1 / 96.0) * math.sin(6.0 * mu);

    final sinPhi1 = math.sin(phi1Rad);
    final cosPhi1 = math.cos(phi1Rad);
    final tanPhi1 = math.tan(phi1Rad);

    final n1 = _a / math.sqrt(1.0 - _e2 * sinPhi1 * sinPhi1);
    final t1 = tanPhi1 * tanPhi1;
    final c1 = _ePrime2 * cosPhi1 * cosPhi1;
    final r1 = _a * (1.0 - _e2) / math.pow(1.0 - _e2 * sinPhi1 * sinPhi1, 1.5).toDouble();
    final d = x / (n1 * _k0);

    final latRad = phi1Rad - (n1 * tanPhi1 / r1) * (
        d * d / 2.0
        - (5.0 + 3.0 * t1 + 10.0 * c1 - 4.0 * c1 * c1 - 9.0 * _ePrime2) * d * d * d * d / 24.0
        + (61.0 + 90.0 * t1 + 298.0 * c1 + 45.0 * t1 * t1 - 252.0 * _ePrime2 - 3.0 * c1 * c1) * d * d * d * d * d * d / 720.0
    );

    final lonRad = lonOriginRad + (
        d
        - (1.0 + 2.0 * t1 + c1) * d * d * d / 6.0
        + (5.0 - 2.0 * c1 + 28.0 * t1 - 3.0 * c1 * c1 + 8.0 * _ePrime2 + 24.0 * t1 * t1) * d * d * d * d * d / 120.0
    ) / cosPhi1;

    return {
      'lat': latRad * (180.0 / math.pi),
      'lon': lonRad * (180.0 / math.pi),
    };
  }
}
