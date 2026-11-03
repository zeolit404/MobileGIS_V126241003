import 'dart:io';

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/survey_point.dart';

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

  // Preview Foto Ukuran Penuh
  void _lihatFotoPenuh(String fotoPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(fotoPath)),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 lembut
      body: FutureBuilder<List<SurveyPoint>>(
        future: _futureSurveys,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
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
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final point = data[index];
                final adaFoto = point.fotoPath != null && File(point.fotoPath!).existsSync();

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FITUR IFA: TAMPILKAN FOTO DI RIWAYAT
                        GestureDetector(
                          onTap: adaFoto ? () => _lihatFotoPenuh(point.fotoPath!) : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: adaFoto
                                ? Image.file(
                                    File(point.fotoPath!),
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
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
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Informasi Teks Survei
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                point.nama,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF), // Soft Blue
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  point.kategori,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E40AF),
                                  ),
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

                        // Tombol Hapus
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
          );
        },
      ),
    );
  }
}
