import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/survey_point.dart';

class ExportService {
  // 1. EKSPOR KE CSV (Standar GIS / Spreadsheets)
  static Future<String?> exportToCsv(List<SurveyPoint> data) async {
    final List<List<dynamic>> rows = [
      ['ID', 'Nama Objek', 'Kategori', 'Geometri', 'Latitude', 'Longitude', 'Koordinat Titik-titik', 'Keterangan', 'Waktu', 'Foto Path']
    ];

    for (final p in data) {
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
        p.fotoPath ?? '',
      ]);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map((e) => '"${e.toString().replaceAll('"', '""')}"').join(','));
    }
    final csvResult = buffer.toString();

    if (kIsWeb) {
      // Pada Web, trigger download via printing/share helper
      await Printing.sharePdf(
        bytes: utf8.encode(csvResult),
        filename: 'Data_Survei_MobileGIS_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      return 'File CSV berhasil diunduh';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Data_Survei_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvResult);
      return file.path;
    }
  }

  // 2. EKSPOR KE EXCEL (XLSX)
  static Future<String?> exportToExcel(List<SurveyPoint> data) async {
    final excel = Excel.createExcel();
    final sheet = excel['Data_Survei_GIS'];
    excel.setDefaultSheet('Data_Survei_GIS');

    // Header Excel
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
    ]);

    for (final p in data) {
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
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'Data_Survei_MobileGIS_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
      return 'File Excel berhasil diunduh';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Data_Survei_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  // 3. EKSPOR KE PDF (Laporan Resmi Akademik Ber-Kop)
  static Future<void> exportToPdf(List<SurveyPoint> data) async {
    final pdf = pw.Document();

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

            // Tabel Data Hasil Survei
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Nama Objek', 'Kategori', 'Tipe', 'Latitude', 'Longitude', 'Keterangan', 'Waktu'],
              data: List.generate(data.length, (index) {
                final p = data[index];
                return [
                  (index + 1).toString(),
                  p.nama,
                  p.kategori,
                  p.tipeGeometri,
                  p.latitude.toStringAsFixed(5),
                  p.longitude.toStringAsFixed(5),
                  p.keterangan ?? '-',
                  p.waktu,
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
            ),

            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Data: ${data.length} objek spasial', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Text('Verifikasi: Dr. Agus Aris, S.Kel., M.Sc.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
              ],
            ),
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

  // 4. EKSPOR KE DOCX (Format Dokumen Word Siap Buka di MS Word)
  static Future<String?> exportToDocx(List<SurveyPoint> data) async {
    // Format XML/HTML Word Document compliant (.doc / .docx compatible)
    final buffer = StringBuffer();
    buffer.writeln('<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns="http://www.w3.org/TR/REC-html40">');
    buffer.writeln('<head><meta charset="utf-8"><title>Laporan Hasil Survei Mobile GIS</title>');
    buffer.writeln('<style>');
    buffer.writeln('body { font-family: Calibri, Arial, sans-serif; }');
    buffer.writeln('h2 { color: #1E3A8A; text-align: center; }');
    buffer.writeln('.sub { text-align: center; font-size: 11pt; color: #475569; margin-bottom: 20px; }');
    buffer.writeln('table { width: 100%; border-collapse: collapse; margin-top: 15px; }');
    buffer.writeln('th { background-color: #1E40AF; color: white; padding: 8px; border: 1px solid #CBD5E1; font-size: 10pt; }');
    buffer.writeln('td { padding: 6px 8px; border: 1px solid #CBD5E1; font-size: 9.5pt; }');
    buffer.writeln('tr:nth-child(even) { background-color: #F8FAFC; }');
    buffer.writeln('</style></head><body>');

    buffer.writeln('<h2>LAPORAN HASIL SURVEI SPASIAL MOBILE GIS</h2>');
    buffer.writeln('<div class="sub">Program Studi D4 Penginderaan Jauh & SIG — Universitas Hasanuddin<br>');
    buffer.writeln('Surveyor: <b>M. Arief Abdillah (NIM: V126241003)</b> | Dosen: <b>Dr. Agus Aris, S.Kel., M.Sc.</b></div>');

    buffer.writeln('<table>');
    buffer.writeln('<tr><th>No</th><th>Nama Objek</th><th>Kategori</th><th>Geometri</th><th>Latitude</th><th>Longitude</th><th>Keterangan</th><th>Waktu</th></tr>');

    for (int i = 0; i < data.length; i++) {
      final p = data[i];
      buffer.writeln('<tr>');
      buffer.writeln('<td>${i + 1}</td>');
      buffer.writeln('<td><b>${p.nama}</b></td>');
      buffer.writeln('<td>${p.kategori}</td>');
      buffer.writeln('<td>${p.tipeGeometri}</td>');
      buffer.writeln('<td>${p.latitude.toStringAsFixed(5)}</td>');
      buffer.writeln('<td>${p.longitude.toStringAsFixed(5)}</td>');
      buffer.writeln('<td>${p.keterangan ?? "-"}</td>');
      buffer.writeln('<td>${p.waktu}</td>');
      buffer.writeln('</tr>');
    }

    buffer.writeln('</table>');
    buffer.writeln('<p style="margin-top:25px; font-size:9pt; color:#64748B;">Total data terekam: ${data.length} record. Dicetak otomatis oleh Aplikasi Mobile GIS Unhas.</p>');
    buffer.writeln('</body></html>');

    final docxContent = buffer.toString();

    if (kIsWeb) {
      await Printing.sharePdf(
        bytes: utf8.encode(docxContent),
        filename: 'Laporan_Survei_MobileGIS_${DateTime.now().millisecondsSinceEpoch}.doc',
      );
      return 'File Dokumen Word berhasil diunduh';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Laporan_Survei_${DateTime.now().millisecondsSinceEpoch}.doc');
      await file.writeAsString(docxContent);
      return file.path;
    }
  }
}
