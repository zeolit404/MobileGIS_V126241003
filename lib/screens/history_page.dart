import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/survey_point.dart';
import '../services/export_service.dart';
import '../utils/platform_image_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<SurveyPoint>> _futureSurveys;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _futureSurveys = DatabaseHelper.instance.getAllSurveys();
    });
  }

  Future<void> _hapusData(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus data survei ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteSurvey(id);
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil dihapus')),
        );
      }
    }
  }

  // Dialog Pilihan Ekspor Data
  void _bukaMenuEkspor(List<SurveyPoint> data) {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Belum ada data survei untuk diekspor!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_for_offline, color: Color(0xFF2563EB), size: 28),
                const SizedBox(width: 10),
                Text(
                  'Ekspor Data Survei (${data.length} Record)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih format file hasil ekstraksi data spasial untuk laporan:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const Divider(height: 24),

            // Opsi 1: PDF Laporan Resmi
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEE2E2),
                child: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              ),
              title: const Text('Format PDF (Laporan Akademik Resmi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Tabel rapi ber-kop Universitas Hasanuddin siap cetak/simpan', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                await ExportService.exportToPdf(data);
              },
            ),

            // Opsi 2: Excel (XLSX)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFDCFCE7),
                child: Icon(Icons.table_chart, color: Colors.green),
              ),
              title: const Text('Format Excel (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Spreadsheet Microsoft Excel untuk pengolahan tabular lanjutan', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await ExportService.exportToExcel(data);
                if (mounted && res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $res')));
                }
              },
            ),

            // Opsi 3: CSV (Standar GIS / QGIS / ArcGIS)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0E7FF),
                child: Icon(Icons.text_snippet, color: Color(0xFF4F46E5)),
              ),
              title: const Text('Format CSV (Standar SIG / QGIS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Kompatibel langsung diimpor ke software QGIS & ArcGIS', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await ExportService.exportToCsv(data);
                if (mounted && res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $res')));
                }
              },
            ),

            // Opsi 4: Word (DOCX / DOC)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.description, color: Color(0xFF2563EB)),
              ),
              title: const Text('Format Word (.doc / .docx)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Dokumen tabel Microsoft Word yang dapat diedit langsung', style: TextStyle(fontSize: 11)),
              onTap: () async {
                Navigator.pop(ctx);
                final res = await ExportService.exportToDocx(data);
                if (mounted && res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $res')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _lihatFotoPenuh(String fotoPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformImageHelper.buildImage(
              fotoPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Padding(
                padding: EdgeInsets.all(30),
                child: Icon(Icons.broken_image, size: 50, color: Colors.black38),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? fotoPath) {
    if (fotoPath == null || fotoPath.isEmpty) {
      return Container(
        width: 76,
        height: 76,
        color: Colors.grey.shade200,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography_outlined, color: Colors.black38),
            SizedBox(height: 2),
            Text('No Foto', style: TextStyle(fontSize: 10, color: Colors.black38)),
          ],
        ),
      );
    }

    return PlatformImageHelper.buildImage(
      fotoPath,
      width: 76,
      height: 76,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 76,
        height: 76,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image_outlined, color: Colors.black38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<List<SurveyPoint>>(
        future: _futureSurveys,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 10),
                    Text('Gagal memuat: ${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _refreshData, child: const Text('Coba Lagi')),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];

          return Stack(
            children: [
              if (data.isEmpty)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 56, color: Colors.black26),
                      SizedBox(height: 10),
                      Text(
                        'Belum ada data survei tersimpan.',
                        style: TextStyle(color: Colors.black45, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final point = data[index];
                      final adaFoto = point.fotoPath != null && point.fotoPath!.isNotEmpty;

                      IconData geomIcon = Icons.place;
                      Color geomColor = Colors.amber.shade800;
                      if (point.tipeGeometri == 'Line') {
                        geomIcon = Icons.polyline;
                        geomColor = Colors.blue.shade700;
                      } else if (point.tipeGeometri == 'Polygon') {
                        geomIcon = Icons.pentagon_outlined;
                        geomColor = Colors.purple.shade700;
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: adaFoto ? () => _lihatFotoPenuh(point.fotoPath!) : null,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildThumbnail(point.fotoPath),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            point.nama,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: geomColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(geomIcon, size: 12, color: geomColor),
                                              const SizedBox(width: 3),
                                              Text(
                                                point.tipeGeometri,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: geomColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        point.kategori,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${point.latitude.toStringAsFixed(5)}, Lon: ${point.longitude.toStringAsFixed(5)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                    ),
                                    Text(
                                      'Waktu: ${point.waktu}',
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                onPressed: point.id != null ? () => _hapusData(point.id!) : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Tombol Floating Ekspor Data (Multi Format)
              if (data.isNotEmpty)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'btnEksporData',
                    onPressed: () => _bukaMenuEkspor(data),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.download),
                    label: const Text('Ekspor Tabel (PDF/Excel/CSV/Word)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
