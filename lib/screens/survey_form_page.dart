import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../db/database_helper.dart';
import '../models/survey_point.dart';
import '../services/location_service.dart';
import '../utils/platform_image_helper.dart';

class SurveyFormPage extends StatefulWidget {
  const SurveyFormPage({super.key});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  // 1. Tipe Geometri: Point, Line, Polygon
  String _tipeGeometri = 'Point';

  // 2. Daftar Titik Koordinat Tambahan untuk Line dan Polygon
  final List<Map<String, double>> _multiPoints = [];

  bool _isManualCoordinate = false;

  String? _selectedKategori = 'Pendidikan';
  final List<String> _kategoriList = [
    'Pendidikan',
    'Tempat Ibadah',
    'Kesehatan',
    'Olahraga',
    'Jalan & Jalur',
    'Batas & Lahan',
    'Fasilitas Umum',
    'Lainnya',
  ];

  String? _savedImagePath;
  bool _isLoadingLocation = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _namaController.dispose();
    _keteranganController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  // Mengambil Koordinat GPS
  Future<void> _ambilLokasi() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Lokasi GPS berhasil dikunci!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengambil lokasi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Tambahkan titik saat ini ke dalam list MultiPoints (untuk Line / Polygon)
  void _tambahTitikKeList() {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Kunci koordinat Latitude & Longitude terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _multiPoints.add({'lat': lat, 'lng': lon});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Titik #${_multiPoints.length} berhasil ditambahkan!'),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _hapusTitikDariList(int index) {
    setState(() {
      _multiPoints.removeAt(index);
    });
  }

  // Mengambil Foto
  Future<void> _ambilFoto(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64String';

      setState(() {
        _savedImagePath = dataUri;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 Foto berhasil dimuat!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal mengambil foto: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Menyimpan Data
  Future<void> _simpanSurvei() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Koordinat utama Latitude & Longitude wajib diisi!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validasi titik untuk Line / Polygon
    if (_tipeGeometri == 'Line' && _multiPoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Garis (Line) membutuhkan minimal 2 titik! Tambahkan titik di bawah.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_tipeGeometri == 'Polygon' && _multiPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Area (Polygon) membutuhkan minimal 3 titik! Tambahkan titik di bawah.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final point = SurveyPoint(
        nama: _namaController.text.trim(),
        kategori: _selectedKategori ?? 'Umum',
        keterangan: _keteranganController.text.trim().isEmpty ? null : _keteranganController.text.trim(),
        latitude: lat,
        longitude: lon,
        fotoPath: _savedImagePath,
        waktu: DateTime.now().toLocal().toString().split('.')[0],
        tipeGeometri: _tipeGeometri,
        koordinatList: _multiPoints.isNotEmpty ? jsonEncode(_multiPoints) : null,
      );

      await DatabaseHelper.instance.insertSurvey(point);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Data survei geospasial berhasil disimpan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        _namaController.clear();
        _keteranganController.clear();
        _latController.clear();
        _lonController.clear();
        setState(() {
          _savedImagePath = null;
          _multiPoints.clear();
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal menyimpan data: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Pemilihan Tipe Geometri (Point, Line, Polygon)
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.architecture, color: Color(0xFF2563EB)),
                      const SizedBox(width: 10),
                      const Text(
                        'Tipe Geometri:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Point', label: Text('Titik'), icon: Icon(Icons.place, size: 16)),
                          ButtonSegment(value: 'Line', label: Text('Garis'), icon: Icon(Icons.polyline, size: 16)),
                          ButtonSegment(value: 'Polygon', label: Text('Area'), icon: Icon(Icons.pentagon_outlined, size: 16)),
                        ],
                        selected: {_tipeGeometri},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _tipeGeometri = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Input Nama & Kategori
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Objek / Fitur Survei *',
                  hintText: 'Contoh: Jalan Lingkar Unhas / Gedung Rektorat',
                  prefixIcon: Icon(Icons.edit_location_alt_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama objek tidak boleh kosong' : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _selectedKategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori Fasilitas *',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _kategoriList.map((kat) => DropdownMenuItem(value: kat, child: Text(kat))).toList(),
                onChanged: (val) => setState(() => _selectedKategori = val),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _keteranganController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Tambahan (Opsional)',
                  hintText: 'Kondisi fisik, dimensi, perkerasan jalan, dsb.',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Panel Koordinat (GPS / Input Mandiri)
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Text(
                                _tipeGeometri == 'Point' ? 'Koordinat Titik Utama' : 'Koordinat Titik Target',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                _isManualCoordinate ? 'Input Mandiri' : 'GPS',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                              ),
                              Switch(
                                value: _isManualCoordinate,
                                onChanged: (val) => setState(() => _isManualCoordinate = val),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Latitude *',
                                hintText: '-5.135700',
                                prefixIcon: const Icon(Icons.navigation_outlined, size: 18),
                                border: const OutlineInputBorder(),
                                filled: !_isManualCoordinate,
                                fillColor: _isManualCoordinate ? Colors.white : Colors.grey.shade100,
                              ),
                              readOnly: !_isManualCoordinate,
                              validator: (val) => (val == null || double.tryParse(val.trim()) == null) ? 'Angka tidak valid' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _lonController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Longitude *',
                                hintText: '119.488600',
                                prefixIcon: const Icon(Icons.explore_outlined, size: 18),
                                border: const OutlineInputBorder(),
                                filled: !_isManualCoordinate,
                                fillColor: _isManualCoordinate ? Colors.white : Colors.grey.shade100,
                              ),
                              readOnly: !_isManualCoordinate,
                              validator: (val) => (val == null || double.tryParse(val.trim()) == null) ? 'Angka tidak valid' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _ambilLokasi,
                          icon: _isLoadingLocation
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.gps_fixed),
                          label: Text(_isLoadingLocation ? 'Mengambil GPS...' : 'Kunci Lokasi (GPS)'),
                        ),
                      ),

                      // Jika tipe Line atau Polygon: tombol tambah titik ke list
                      if (_tipeGeometri != 'Point') ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            Text(
                              'Titik Tersusun (${_multiPoints.length}):',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _tambahTitikKeList,
                              icon: const Icon(Icons.add_location_alt, size: 16),
                              label: const Text('Tambah Titik'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_multiPoints.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _multiPoints.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final pt = _multiPoints[i];
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.amber.shade700,
                                    child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text('${pt['lat']!.toStringAsFixed(6)}, ${pt['lng']!.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                                    onPressed: () => _hapusTitikDariList(i),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Panel Foto
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.teal),
                          SizedBox(width: 8),
                          Text('Foto Dokumentasi Lapangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_savedImagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: PlatformImageHelper.buildImage(
                            _savedImagePath!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('Foto dokumen berhasil dipilih', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ] else
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.black38),
                                SizedBox(height: 4),
                                Text('Belum ada foto objek', style: TextStyle(fontSize: 12, color: Colors.black45)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _ambilFoto(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Kamera'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _ambilFoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galeri'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 5. Tombol Simpan
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _simpanSurvei,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'Menyimpan Data...' : 'Simpan Fitur Geospasial',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
