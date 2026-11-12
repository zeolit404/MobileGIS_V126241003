import 'dart:io';

import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/digitization_result.dart';
import '../models/survey_point.dart';
import '../utils/coordinate_converter.dart';

class _HistoryImage {
  const _HistoryImage.photo(this.point) : digitization = null;
  const _HistoryImage.digitization(this.digitization) : point = null;

  final SurveyPoint? point;
  final DigitizationResult? digitization;

  String get imagePath => point?.fotoPath ?? digitization!.imagePath;
  String get title => point?.nama.isNotEmpty == true ? point!.nama : (point?.kategori ?? 'Hasil Digitasi');
  String get waktu => point?.waktu ?? digitization!.waktu;
  String get geometryType => point?.tipeGeometri ?? 'Line/Polygon';
}

class PhotoHistoryPage extends StatefulWidget {
  const PhotoHistoryPage({super.key});

  @override
  State<PhotoHistoryPage> createState() => _PhotoHistoryPageState();
}

class _PhotoHistoryPageState extends State<PhotoHistoryPage> {
  late Future<List<_HistoryImage>> _futurePhotos;

  @override
  void initState() {
    super.initState();
    _futurePhotos = _muatFoto();
  }

  // Gabungkan foto survei lapangan dan screenshot digitasi
  Future<List<_HistoryImage>> _muatFoto() async {
    final surveys = await DatabaseHelper.instance.getAllSurveys();
    final digitizations = await DatabaseHelper.instance.getAllDigitizationResults();

    return [
      for (final s in surveys)
        if (s.fotoPath != null && s.fotoPath!.isNotEmpty && File(s.fotoPath!).existsSync())
          _HistoryImage.photo(s),
      for (final d in digitizations)
        if (d.imagePath.isNotEmpty && File(d.imagePath).existsSync())
          _HistoryImage.digitization(d),
    ]..sort((a, b) => b.waktu.compareTo(a.waktu));
  }

  void _segarkan() {
    setState(() {
      _futurePhotos = _muatFoto();
    });
  }

  void _bukaDetail(SurveyPoint point) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PhotoDetailPage(point: point)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _segarkan(),
        child: FutureBuilder<List<_HistoryImage>>(
          future: _futurePhotos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final fotos = snapshot.data ?? [];
            if (fotos.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 140),
                  Icon(
                    Icons.photo_library_outlined,
                    size: 72,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Belum ada foto dokumentasi survei.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Ambil foto saat mengisi formulir survei lapangan.',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                    ),
                  ),
                ],
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: fotos.length,
              itemBuilder: (context, index) {
                final item = fotos[index];
                return GestureDetector(
                  onTap: () {
                    if (item.point != null) {
                      _bukaDetail(item.point!);
                    } else if (item.digitization != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _DigitizationDetailPage(result: item.digitization!),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(item.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                        // Badge Geometri di Kanan Atas
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.geometryType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Bar Keterangan di Bawah
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.waktu,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade300,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DigitizationDetailPage extends StatelessWidget {
  final DigitizationResult result;

  const _DigitizationDetailPage({required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final distance = result.distanceMeters < 1000
        ? '${result.distanceMeters.toStringAsFixed(0)} m'
        : '${(result.distanceMeters / 1000).toStringAsFixed(2)} km';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Hasil Digitasi')),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(result.imagePath),
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Jarak / Keliling', distance, Icons.straighten, Colors.blue),
                _buildStatItem('Jumlah Simpul', '${result.vertexCount} Titik', Icons.grain, Colors.orange),
                _buildStatItem('Waktu', result.waktu.split(' ').first, Icons.calendar_today, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _PhotoDetailPage extends StatelessWidget {
  final SurveyPoint point;

  const _PhotoDetailPage({required this.point});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final utm = CoordinateConverter.latLonToUtm(point.latitude, point.longitude);

    return Scaffold(
      appBar: AppBar(title: Text(point.nama.isNotEmpty ? point.nama : point.kategori)),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(point.fotoPath!),
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        point.nama,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        point.tipeGeometri,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Kategori: ${point.kategori}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('WGS84 : ${point.latitude.toStringAsFixed(6)}°, ${point.longitude.toStringAsFixed(6)}°'),
                Text(
                  'UTM ${utm.zoneString}: Easting ${utm.easting.toStringAsFixed(1)} m, Northing ${utm.northing.toStringAsFixed(1)} m',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('Waktu   : ${point.waktu}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (point.keterangan != null && point.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Catatan: ${point.keterangan!}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
