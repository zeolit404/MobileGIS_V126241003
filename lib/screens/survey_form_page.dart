import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // widget dasar Flutter (Scaffold, Button, dll)
import 'package:geolocator/geolocator.dart'; // untuk tipe data Position (lat & long GPS)
import 'package:image_picker/image_picker.dart'; // untuk membuka kamera
import 'package:path/path.dart' as p; // membantu mengolah nama/alamat file
import 'package:path_provider/path_provider.dart'; // mencari folder penyimpanan di HP
import '../db/database_helper.dart'; // class untuk simpan data ke database SQLite
import '../models/survey_point.dart'; // model/struktur data satu titik survei
import '../services/location_service.dart'; // class untuk mengambil lokasi GPS (bisa tambahkan ini)

class SurveyFormPage extends StatefulWidget {
  const SurveyFormPage({super.key});

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller Input Teks
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  // Kategori Survei
  String? _selectedKategori = 'Pendidikan';
  final List<String> _kategoriList = [
    'Pendidikan',
    'Tempat Ibadah',
    'Kesehatan',
    'Olahraga',
    'Fasilitas Umum',
    'Lainnya',
  ];

  // Data Lokasi & Foto
  Position? _currentPosition;
  File? _imageFile;
  String? _savedImagePath;
  bool _isLoadingLocation = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _namaController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  // Mengambil Koordinat GPS
  Future<void> _ambilLokasi() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Lokasi GPS berhasil didapatkan!'),
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

  // Mengambil Foto via Kamera atau Galeri
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

      if (kIsWeb) {
        // Pada Web platform
        setState(() {
          _savedImagePath = pickedFile.path;
        });
      } else {
        // Pada Android / Perangkat Fisik: simpan permanen ke folder dokumen aplikasi
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'SURVEY_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

        setState(() {
          _imageFile = savedImage;
          _savedImagePath = savedImage.path;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📷 Foto berhasil diambil dan disimpan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengambil foto: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Menyimpan Data ke SQLite
  Future<void> _simpanSurvei() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Koordinat GPS wajib diambil terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newPoint = SurveyPoint(
        nama: _namaController.text.trim(),
        kategori: _selectedKategori ?? 'Umum',
        keterangan: _keteranganController.text.trim().isEmpty
            ? null
            : _keteranganController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        fotoPath: _savedImagePath,
        waktu: DateTime.now().toLocal().toString().split('.')[0],
      );

      // Simpan ke database lokal SQLite
      if (!kIsWeb) {
        await DatabaseHelper.instance.insertSurvey(newPoint);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Data survei berhasil disimpan ke database!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Reset form setelah simpan
        _namaController.clear();
        _keteranganController.clear();
        setState(() {
          _currentPosition = null;
          _imageFile = null;
          _savedImagePath = null;
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menyimpan data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Survei Lapangan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Input Nama Objek / Fasilitas
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Fasilitas / Objek *',
                  hintText: 'Contoh: Gedung Rektorat Unhas',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama fasilitas tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Dropdown Kategori
              DropdownButtonFormField<String>(
                initialValue: _selectedKategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori Fasilitas *',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _kategoriList.map((kat) {
                  return DropdownMenuItem(
                    value: kat,
                    child: Text(kat),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedKategori = val);
                },
              ),
              const SizedBox(height: 14),

              // 3. Input Keterangan / Deskripsi
              TextFormField(
                controller: _keteranganController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Tambahan (Opsional)',
                  hintText: 'Kondisi fisik, fasilitas aksesibilitas, dsb.',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // 4. Panel Koordinat GPS
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.my_location, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            'Akuisisi Koordinat GPS',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_currentPosition != null) ...[
                        Text(
                          'Latitude  : ${_currentPosition!.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Longitude : ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Akurasi   : ±${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ] else
                        const Text(
                          'Belum ada koordinat. Tekan tombol di bawah untuk mengambil titik GPS saat ini.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _ambilLokasi,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.gps_fixed),
                          label: Text(_isLoadingLocation ? 'Mengambil GPS...' : 'Ambil Lokasi Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 5. Panel Foto Lapangan & Geotagging
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            'Foto Dokumentasi Lapangan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_imageFile != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.basename(_imageFile!.path),
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ] else
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.black38),
                                SizedBox(height: 4),
                                Text(
                                  'Belum ada foto objek',
                                  style: TextStyle(fontSize: 12, color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
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
              const SizedBox(height: 24),

              // 6. Tombol Simpan Survei
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _simpanSurvei,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'Menyimpan Data...' : 'Simpan Data Survei',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
