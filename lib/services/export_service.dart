import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/survey_point.dart';
import '../utils/file_saver.dart';

class ExportService {
  // Helper internal untuk mengekstrak bytes foto base64
  static Uint8List? _decodePhotoBytes(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      if (path.startsWith('data:image')) {
        final commaIndex = path.indexOf(',');
        if (commaIndex != -1) {
          return base64Decode(path.substring(commaIndex + 1));
        }
      }
    } catch (_) {}
    return null;
  }

  // 1. EKSPOR KE CSV (Standar GIS / Spreadsheets) dengan kolom Foto & Geotagging
  static Future<String?> exportToCsv(List<SurveyPoint> data) async {
    final List<List<dynamic>> rows = [
      [
        'ID',
        'Nama Objek',
        'Kategori',
        'Geometri',
        'Latitude',
        'Longitude',
        'Koordinat Titik-titik',
        'Keterangan',
        'Waktu',
        'Foto / Geotagging',
      ]
    ];

    for (final p in data) {
      final geotagStatus = (p.fotoPath != null && p.fotoPath!.isNotEmpty)
          ? 'Foto Geotagged [Lat: ${p.latitude.toStringAsFixed(6)}, Lon: ${p.longitude.toStringAsFixed(6)}]'
          : 'Tidak Ada Foto';

      rows.add([
        p.id ?? '',
        p.nama,
        p.kategori,
        p.tipeGeometri,
        p.latitude,
        p.longitude,
        p.koordinatList ?? '',
        p.keterangan ?? '',
        p.waktu,
        geotagStatus,
      ]);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
    }
    final csvResult = buffer.toString();

    return await FileSaver.saveFile(
      'Data_Survei_MobileGIS_${DateTime.now().millisecondsSinceEpoch}.csv',
      Uint8List.fromList(utf8.encode(csvResult)),
    );
  }

  // 2. EKSPOR KE EXCEL (XLSX) dengan kolom Foto & Geotagging
  static Future<String?> exportToExcel(List<SurveyPoint> data) async {
    final excel = Excel.createExcel();
    final sheet = excel['Data_Survei_GIS'];
    excel.setDefaultSheet('Data_Survei_GIS');

    // Header Excel dengan kolom Foto / Geotagging
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Nama Objek'),
      TextCellValue('Kategori'),
      TextCellValue('Geometri'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      TextCellValue('Titik Tambahan'),
      TextCellValue('Keterangan'),
      TextCellValue('Waktu Survei'),
      TextCellValue('Foto / Geotagging'),
    ]);

    for (final p in data) {
      final geotagStatus = (p.fotoPath != null && p.fotoPath!.isNotEmpty)
          ? 'Foto Geotagged [Lat: ${p.latitude.toStringAsFixed(6)}, Lon: ${p.longitude.toStringAsFixed(6)}]'
          : 'Tidak Ada Foto';

      sheet.appendRow([
        IntCellValue(p.id ?? 0),
        TextCellValue(p.nama),
        TextCellValue(p.kategori),
        TextCellValue(p.tipeGeometri),
        DoubleCellValue(p.latitude),
        DoubleCellValue(p.longitude),
        TextCellValue(p.koordinatList ?? '-'),
        TextCellValue(p.keterangan ?? '-'),
        TextCellValue(p.waktu),
        TextCellValue(geotagStatus),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    return await FileSaver.saveFile(
      'Data_Survei_MobileGIS_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      Uint8List.fromList(bytes),
    );
  }

  // 3. EKSPOR KE PDF (Laporan Resmi Akademik Ber-Kop + Lampiran Geotagging)
  static Future<void> exportToPdf(List<SurveyPoint> data) async {
    final pdf = pw.Document();

    // Persiapkan foto geotagging jika tersedia
    final photoList = <Map<String, dynamic>>[];
    for (final p in data) {
      final bytes = _decodePhotoBytes(p.fotoPath);
      if (bytes != null) {
        photoList.add({'point': p, 'image': pw.MemoryImage(bytes)});
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Kop Dokumen Resmi
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LAPORAN HASIL SURVEI SPASIAL MOBILE GIS',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                      ),
                      pw.Text(
                        'Program Studi D4 Penginderaan Jauh & SIG — Universitas Hasanuddin',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Surveyor: M. Arief Abdillah (V126241003)', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Tanggal Cetak: ${DateTime.now().toLocal().toString().split('.')[0]}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Tabel Data Hasil Survei dengan Kolom Foto / Geotagging
            pw.TableHelper.fromTextArray(
              headers: [
                'No',
                'Nama Objek',
                'Kategori',
                'Tipe',
                'Latitude',
                'Longitude',
                'Foto / Geotagging',
                'Keterangan',
                'Waktu',
              ],
              data: List.generate(data.length, (index) {
                final p = data[index];
                final hasPhoto = p.fotoPath != null && p.fotoPath!.isNotEmpty;
                return [
                  (index + 1).toString(),
                  p.nama,
                  p.kategori,
                  p.tipeGeometri,
                  p.latitude.toStringAsFixed(5),
                  p.longitude.toStringAsFixed(5),
                  hasPhoto ? 'Ada (Geotag)' : '-',
                  p.keterangan ?? '-',
                  p.waktu,
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            ),

            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Data: ${data.length} objek spasial | Foto ter-geotag: ${photoList.length} objek', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Text('Dosen Pengampu: Dr. Agus Aris, S.Kel., M.Sc.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
              ],
            ),

            // Lampiran Foto Dokumentasi Geotagging Lapangan jika ada foto
            if (photoList.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Text(
                'LAMPIRAN DOKUMENTASI FOTO LAPANGAN & GEOTAGGING',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 12,
                runSpacing: 12,
                children: photoList.map((item) {
                  final SurveyPoint pt = item['point'] as SurveyPoint;
                  final pw.MemoryImage img = item['image'] as pw.MemoryImage;
                  return pw.Container(
                    width: 175,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          height: 100,
                          width: double.infinity,
                          child: pw.Image(img, fit: pw.BoxFit.cover),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(pt.nama, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
                        pw.Text('Kat: ${pt.kategori} | ${pt.tipeGeometri}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                        pw.Text('📍 Lat: ${pt.latitude.toStringAsFixed(5)}, Lon: ${pt.longitude.toStringAsFixed(5)}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blue800)),
                        pw.Text('Waktu: ${pt.waktu}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ];
        },
      ),
    );

    // Tampilkan Dialog Cetak / Simpan PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Survei_MobileGIS_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // 4. EKSPOR KE DOCX / WORD dengan Kolom Foto & Geotagging
  static Future<String?> exportToDocx(List<SurveyPoint> data) async {
    final buffer = StringBuffer();
    buffer.writeln('<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns="http://www.w3.org/TR/REC-html40">');
    buffer.writeln('<head><meta charset="utf-8"><title>Laporan Hasil Survei Mobile GIS</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: Calibri, Arial, sans-serif; }');
    buffer.writeln('h2 { color: #1E3A8A; text-align: center; }');
    buffer.writeln('.sub { text-align: center; font-size: 11pt; color: #475569; margin-bottom: 20px; }');
    buffer.writeln('table { width: 100%; border-collapse: collapse; margin-top: 15px; }');
    buffer.writeln('th { background-color: #1E40AF; color: white; padding: 8px; border: 1px solid #CBD5E1; font-size: 10pt; }');
    buffer.writeln('td { padding: 6px 8px; border: 1px solid #CBD5E1; font-size: 9.5pt; vertical-align: top; }');
    buffer.writeln('tr:nth-child(even) { background-color: #F8FAFC; }');
    buffer.writeln('</style></head><body>');

    buffer.writeln('<h2>LAPORAN HASIL SURVEI SPASIAL MOBILE GIS</h2>');
    buffer.writeln('<div class="sub">Program Studi D4 Penginderaan Jauh & SIG — Universitas Hasanuddin<br>');
    buffer.writeln('Surveyor: <b>M. Arief Abdillah (NIM: V126241003)</b> | Dosen Pengampu: <b>Dr. Agus Aris, S.Kel., M.Sc.</b></div>');

    buffer.writeln('<table>');
    buffer.writeln('<tr><th>No</th><th>Nama Objek</th><th>Kategori</th><th>Geometri</th><th>Latitude</th><th>Longitude</th><th>Foto / Geotagging</th><th>Keterangan</th><th>Waktu</th></tr>');

    for (int i = 0; i < data.length; i++) {
      final p = data[i];
      final hasPhoto = p.fotoPath != null && p.fotoPath!.isNotEmpty;
      final fotoCell = hasPhoto
          ? '<img src="${p.fotoPath}" width="80" style="border-radius:4px; border:1px solid #CBD5E1;"/><br><span style="font-size:8pt; color:#2563EB;">📍 Geotag: ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}</span>'
          : '<span style="color:#94A3B8;">Tidak Ada</span>';

      buffer.writeln('<tr>');
      buffer.writeln('<td>${i + 1}</td>');
      buffer.writeln('<td><b>${p.nama}</b></td>');
      buffer.writeln('<td>${p.kategori}</td>');
      buffer.writeln('<td>${p.tipeGeometri}</td>');
      buffer.writeln('<td>${p.latitude.toStringAsFixed(5)}</td>');
      buffer.writeln('<td>${p.longitude.toStringAsFixed(5)}</td>');
      buffer.writeln('<td>$fotoCell</td>');
      buffer.writeln('<td>${p.keterangan ?? "-"}</td>');
      buffer.writeln('<td>${p.waktu}</td>');
      buffer.writeln('</tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('<p style="margin-top:25px; font-size:9pt; color:#64748B;">Total data terekam: ${data.length} record. Dicetak otomatis oleh Aplikasi Mobile GIS Unhas.</p>');
    buffer.writeln('</body></html>');

    final docxContent = buffer.toString();

    return await FileSaver.saveFile(
      'Laporan_Survei_MobileGIS_${DateTime.now().millisecondsSinceEpoch}.doc',
      Uint8List.fromList(utf8.encode(docxContent)),
    );
  }

  // 5. EKSPOR KE GEOJSON (Standar Vektor GIS / QGIS / ArcGIS) dengan atribut Geotagging
  static Future<String?> exportToGeoJson(List<SurveyPoint> data) async {
    final features = data.map((p) {
      Map<String, dynamic> geometry;
      if (p.tipeGeometri == 'Line' && p.koordinatList != null) {
        try {
          final list = jsonDecode(p.koordinatList!) as List;
          final coords = list.map((e) => [e['lng'], e['lat']]).toList();
          geometry = {'type': 'LineString', 'coordinates': coords};
        } catch (_) {
          geometry = {'type': 'Point', 'coordinates': [p.longitude, p.latitude]};
        }
      } else if (p.tipeGeometri == 'Polygon' && p.koordinatList != null) {
        try {
          final list = jsonDecode(p.koordinatList!) as List;
          final coords = list.map((e) => [e['lng'], e['lat']]).toList();
          if (coords.isNotEmpty && (coords.first[0] != coords.last[0] || coords.first[1] != coords.last[1])) {
            coords.add(coords.first);
          }
          geometry = {'type': 'Polygon', 'coordinates': [coords]};
        } catch (_) {
          geometry = {'type': 'Point', 'coordinates': [p.longitude, p.latitude]};
        }
      } else {
        geometry = {'type': 'Point', 'coordinates': [p.longitude, p.latitude]};
      }

      return {
        'type': 'Feature',
        'geometry': geometry,
        'properties': {
          'id': p.id,
          'nama': p.nama,
          'kategori': p.kategori,
          'tipe_geometri': p.tipeGeometri,
          'latitude': p.latitude,
          'longitude': p.longitude,
          'keterangan': p.keterangan ?? '',
          'waktu': p.waktu,
          'foto_geotagging': (p.fotoPath != null && p.fotoPath!.isNotEmpty)
              ? 'Tersedia [Lat: ${p.latitude}, Lon: ${p.longitude}]'
              : 'Tidak Ada',
          'foto_data_uri': p.fotoPath ?? '',
        },
      };
    }).toList();

    final geoJsonMap = {
      'type': 'FeatureCollection',
      'name': 'Data_Survei_MobileGIS',
      'crs': {
        'type': 'name',
        'properties': {'name': 'urn:ogc:def:crs:OGC:1.3:CRS84'}
      },
      'features': features,
    };

    final geoJsonString = const JsonEncoder.withIndent('  ').convert(geoJsonMap);
    return await FileSaver.saveFile(
      'Data_Survei_MobileGIS_${DateTime.now().millisecondsSinceEpoch}.geojson',
      Uint8List.fromList(utf8.encode(geoJsonString)),
    );
  }
}

