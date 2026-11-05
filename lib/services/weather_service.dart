import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final String location;
  final double temperature;
  final String condition;
  final IconData icon;

  const WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.icon,
  });

  String get tempString => '${temperature.toStringAsFixed(0)}°C';
}

class WeatherService {
  // Koordinat Makassar (Kampus Unhas Tamalanrea)
  static const double _makassarLat = -5.1357;
  static const double _makassarLon = 119.4886;

  static Future<WeatherData> getMakassarWeather() async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$_makassarLat&longitude=$_makassarLon'
      '&current=temperature_2m,weather_code'
      '&timezone=Asia%2FMakassar',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        final temp = (current['temperature_2m'] as num).toDouble();
        final code = current['weather_code'] as int;

        final info = _interpretWmoCode(code);
        return WeatherData(
          location: 'Makassar',
          temperature: temp,
          condition: info['label'] as String,
          icon: info['icon'] as IconData,
        );
      }
    } catch (_) {
      // Fallback jika offline atau koneksi timeout
    }

    // Default estimasi cuaca Makassar jika offline
    return const WeatherData(
      location: 'Makassar',
      temperature: 30.0,
      condition: 'Cerah',
      icon: Icons.wb_sunny_rounded,
    );
  }

  static Map<String, dynamic> _interpretWmoCode(int code) {
    if (code == 0) {
      return {'label': 'Cerah', 'icon': Icons.wb_sunny_rounded};
    } else if (code <= 3) {
      return {'label': 'Cerah Berawan', 'icon': Icons.wb_cloudy_rounded};
    } else if (code <= 48) {
      return {'label': 'Berkabut', 'icon': Icons.cloud_outlined};
    } else if (code <= 67) {
      return {'label': 'Hujan Ringan', 'icon': Icons.water_drop_outlined};
    } else if (code <= 82) {
      return {'label': 'Hujan Lebat', 'icon': Icons.grain_rounded};
    } else {
      return {'label': 'Hujan Petir', 'icon': Icons.flash_on_rounded};
    }
  }
}
