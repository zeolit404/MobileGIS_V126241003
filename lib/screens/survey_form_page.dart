import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // widget dasar Flutter (Scaffold, Button, dll)
import 'package:geolocator/geolocator.dart'; // untuk tipe data Position (lat & long GPS)
import 'package:image_picker/image_picker.dart'; // untuk membuka kamera
import 'package:path/path.dart' as p; // membantu mengolah nama/alamat file
import 'package:path_provider/path_provider.dart'; // mencari folder penyimpanan di HP
import '../db/database_helper.dart'; // class untuk simpan data ke database SQLite
import '../models/survey_point.dart'; // model/struktur data satu titik survei
import '../services/location_service.dart'; // class untuk mengambil lokasi GPS

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

  // Controller Input Koordinat Manual (Bisa Diisi Mandiri)
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  // Mode Pengisian Koordinat: 'gps' atau 'manual'
  bool _isManualCoordinate = false;

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
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  // Mengambil Koordinat GPS Otomatis
  Future<void> _ambilLokasi() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
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
        // Pada Web platform (Chrome)
        setState(() {
          _savedImagePath = pickedFile.path;
        });
      } else {
        // Pada Android / Perangkat Fisik
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

  // Menyimpan Data ke SQLite / Memory Store
  Future<void> _simpanSurvei() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ambil nilai koordinat (dari input manual atau GPS)
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Koordinat Latitude & Longitude wajib diisi dengan benar!'),
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
        latitude: lat,
        longitude: lon,
        fotoPath: _savedImagePath,
        waktu: DateTime.now().toLocal().toString().split('.')[0],
      );

      // Simpan menggunakan DatabaseHelper (aman untuk Android maupun Web Chrome)
      await DatabaseHelper.instance.insertSurvey(newPoint);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Data survei berhasil disimpan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Reset form setelah simpan
        _namaController.clear();
        _keteranganController.clear();
        _latController.clear();
        _lonController.clear();
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
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Tambahan (Opsional)',
                  hintText: 'Kondisi fisik, fasilitas aksesibilitas, dsb.',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // 4. Panel Koordinat (Bisa Otomatis GPS atau Diisi Mandiri)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.my_location, color: Colors.blueAccent),
                              SizedBox(width: 8),
                              Text(
                                'Koordinat Spasial',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          // Switch Mode Input Mandiri
                          Row(
                            children: [
                              Text(
                                _isManualCoordinate ? 'Input Mandiri' : 'Mode GPS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isManualCoordinate ? Colors.blueAccent : Colors.grey.shade700,
                                ),
                              ),
                              Switch(
                                value: _isManualCoordinate,
                                onChanged: (val) {
                                  setState(() => _isManualCoordinate = val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Input Mandiri Latitude & Longitude
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: InputDecoration(
                                labelText: 'Latitude *',
                                hintText: '-5.135700',
                                prefixIcon: const Icon(Icons.north_south, size: 18),
                                border: const OutlineInputBorder(),
                                filled: !_isManualCoordinate,
                                fillColor: _isManualCoordinate ? null : Colors.grey.shade100,
                              ),
                              readOnly: !_isManualCoordinate,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Wajib diisi';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Angka tidak valid';
                                }
                                return null;
                              },
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
                                prefixIcon: const Icon(Icons.east_west, size: 18),
                                border: const OutlineInputBorder(),
                                filled: !_isManualCoordinate,
                                fillColor: _isManualCoordinate ? null : Colors.grey.shade100,
                              ),
                              readOnly: !_isManualCoordinate,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Wajib diisi';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Angka tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tombol Ambil Otomatis dari GPS
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
                          label: Text(_isLoadingLocation
                              ? 'Mengambil GPS...'
                              : 'Kunci Lokasi Otomatis (GPS)'),
                        ),
                      ),
                      if (_currentPosition != null && !_isManualCoordinate) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Akurasi GPS: ±${_currentPosition!.accuracy.toStringAsFixed(1)} meter',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
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
                      if (_savedImagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  _savedImagePath!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : (_imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox()),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.basename(_savedImagePath!),
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
                  backgroundColor: const Color(0xFF1E40AF), // Royal Blue
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
