import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/survey_point.dart';

class ApiService {
  // Ganti dengan URL Web App hasil deploy Google Apps Script (Materi Pertemuan 13)
  static const String scriptUrl = 'GANTI_DENGAN_URL_GOOGLE_APPS_SCRIPT';

  static Future<bool> kirimSurveyPoint(SurveyPoint point) async {
    if (scriptUrl == 'GANTI_DENGAN_URL_GOOGLE_APPS_SCRIPT') {
      debugPrint('URL Google Apps Script belum diatur di lib/services/api_service.dart');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama_surveyor': point.nama,
          'nim': point.nim,
          'kategori': point.kategori,
          'keterangan': point.keterangan ?? '',
          'latitude': point.latitude,
          'longitude': point.longitude,
          'tipe_geometri': point.tipeGeometri,
          'koordinat_list': point.koordinatList ?? '[]',
          'foto_path': point.fotoPath ?? '',
          'waktu': point.waktu,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      debugPrint('Gagal mengirim data survei ke Google Apps Script: $e');
      return false;
    }
  }
}
