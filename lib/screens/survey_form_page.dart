import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../db/database_helper.dart';
import '../models/survey_point.dart';
import '../services/location_service.dart';
import '../utils/coordinate_converter.dart';
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

  // Koordinat WGS 84 (Derajat Desimal)
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  // Koordinat UTM (Proyeksi Metrik)
  final TextEditingController _eastingController = TextEditingController();
  final TextEditingController _northingController = TextEditingController();
  int _utmZone = 50; // Default Zona 50 (Makassar / Sulawesi Selatan)
  String _utmHemisphere = 'S'; // 'S' untuk Belahan Bumi Selatan, 'N' untuk Utara

  // Sistem Koordinat Aktif: 'WGS84' atau 'UTM'
  String _coordinateSystem = 'WGS84';

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
    _eastingController.dispose();
    _northingController.dispose();
    super.dispose();
  }

  // Sinkronisasi otomatis dari WGS 84 ke UTM
  void _syncFromWgs84() {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    if (lat != null && lon != null) {
      final utm = CoordinateConverter.latLonToUtm(lat, lon);
      setState(() {
        _eastingController.text = utm.easting.toStringAsFixed(1);
        _northingController.text = utm.northing.toStringAsFixed(1);
        _utmZone = utm.zone;
        _utmHemisphere = utm.hemisphere;
      });
    }
  }

  // Sinkronisasi otomatis dari UTM ke WGS 84
  void _syncFromUtm() {
    final easting = double.tryParse(_eastingController.text.trim());
    final northing = double.tryParse(_northingController.text.trim());
    if (easting != null && northing != null) {
      final latlon = CoordinateConverter.utmToLatLon(
        easting: easting,
        northing: northing,
        zone: _utmZone,
        hemisphere: _utmHemisphere,
      );
      setState(() {
        _latController.text = latlon['lat']!.toStringAsFixed(6);
        _lonController.text = latlon['lon']!.toStringAsFixed(6);
      });
    }
  }

  // Mengambil Koordinat GPS
  Future<void> _ambilLokasi() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      final utm = CoordinateConverter.latLonToUtm(position.latitude, position.longitude);

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _eastingController.text = utm.easting.toStringAsFixed(1);
        _northingController.text = utm.northing.toStringAsFixed(1);
        _utmZone = utm.zone;
        _utmHemisphere = utm.hemisphere;
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ GPS Terkunci: WGS84 (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}) | UTM ${utm.zoneString}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
    if (_coordinateSystem == 'UTM') {
      _syncFromUtm();
    }

    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Kunci koordinat terlebih dahulu sebelum menambah titik!'),
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
            content: Text('📸 Foto lapangan berhasil disimpan ke survei!'),
            backgroundColor: Colors.green,
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

  // Simpan data ke Database
  Future<void> _simpanSurvei() async {
    if (!_formKey.currentState!.validate()) return;

    // Pastikan koordinat tersinkronisasi jika pengguna dalam mode UTM
    if (_coordinateSystem == 'UTM') {
      _syncFromUtm();
    }

    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Koordinat utama wajib diisi!'),
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
        _eastingController.clear();
        _northingController.clear();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final inputFill = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.architecture, color: Color(0xFF2563EB), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Tipe Geometri Spasial *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          showSelectedIcon: true,
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
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Input Nama & Kategori
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Objek / Fitur Survei *',
                  hintText: 'Contoh: Jalan Lingkar Unhas / Gedung Rektorat',
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: inputFill,
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama objek tidak boleh kosong' : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _selectedKategori,
                decoration: InputDecoration(
                  labelText: 'Kategori Fasilitas *',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: inputFill,
                ),
                items: _kategoriList.map((kat) => DropdownMenuItem(value: kat, child: Text(kat))).toList(),
                onChanged: (val) => setState(() => _selectedKategori = val),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _keteranganController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Keterangan Tambahan (Opsional)',
                  hintText: 'Kondisi fisik, dimensi, perkerasan jalan, dsb.',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: inputFill,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Panel Koordinat (Pilihan Sistem Koordinat: WGS 84 & UTM)
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Koordinat + Switcher GPS / Manual
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Text(
                                _tipeGeometri == 'Point' ? 'Koordinat Titik Utama' : 'Koordinat Titik Target',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() => _isManualCoordinate = !_isManualCoordinate),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isManualCoordinate
                                    ? (isDark ? Colors.blue.shade900.withValues(alpha: 0.5) : Colors.blue.shade50)
                                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isManualCoordinate ? Colors.blue.shade400 : borderColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isManualCoordinate ? Icons.edit_note : Icons.gps_fixed,
                                    size: 14,
                                    color: _isManualCoordinate ? const Color(0xFF38BDF8) : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isManualCoordinate ? 'Input Mandiri' : 'Sensor GPS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isManualCoordinate ? const Color(0xFF38BDF8) : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // MENU SISTEM KOORDINAT (WGS 84 vs UTM)
                      Row(
                        children: [
                          const Icon(Icons.public, color: Color(0xFF2563EB), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Sistem Koordinat Acuan:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          showSelectedIcon: true,
                          segments: const [
                            ButtonSegment(
                              value: 'WGS84',
                              label: Text('WGS 84 (Geografis)'),
                              icon: Icon(Icons.language, size: 16),
                            ),
                            ButtonSegment(
                              value: 'UTM',
                              label: Text('UTM (Proyeksi Metrik)'),
                              icon: Icon(Icons.straighten, size: 16),
                            ),
                          ],
                          selected: {_coordinateSystem},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              _coordinateSystem = newSelection.first;
                              if (_coordinateSystem == 'UTM') {
                                _syncFromWgs84();
                              } else {
                                _syncFromUtm();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // A. FORM INPUT JIKA MODE WGS 84
                      if (_coordinateSystem == 'WGS84') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: 'Latitude (°) *',
                                  hintText: '-5.135700',
                                  prefixIcon: const Icon(Icons.navigation_outlined, size: 18),
                                  border: const OutlineInputBorder(),
                                  filled: !_isManualCoordinate,
                                  fillColor: _isManualCoordinate ? inputFill : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                                ),
                                readOnly: !_isManualCoordinate,
                                onChanged: (_) => _syncFromWgs84(),
                                validator: (val) => (val == null || double.tryParse(val.trim()) == null) ? 'Latitude tidak valid' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _lonController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: 'Longitude (°) *',
                                  hintText: '119.488600',
                                  prefixIcon: const Icon(Icons.explore_outlined, size: 18),
                                  border: const OutlineInputBorder(),
                                  filled: !_isManualCoordinate,
                                  fillColor: _isManualCoordinate ? inputFill : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                                ),
                                readOnly: !_isManualCoordinate,
                                onChanged: (_) => _syncFromWgs84(),
                                validator: (val) => (val == null || double.tryParse(val.trim()) == null) ? 'Longitude tidak valid' : null,
                              ),
                            ),
                          ],
                        ),
                        if (_eastingController.text.isNotEmpty && _northingController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sync_alt, size: 15, color: Color(0xFF2563EB)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Ekuivalen UTM: Zona $_utmZone$_utmHemisphere | X: ${_eastingController.text} m, Y: ${_northingController.text} m',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // B. FORM INPUT JIKA MODE UTM (Proyeksi Metrik)
                      if (_coordinateSystem == 'UTM') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _eastingController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Easting (X / Timur) *',
                                  hintText: '779412.5',
                                  suffixText: 'm',
                                  prefixIcon: const Icon(Icons.east, size: 18),
                                  border: const OutlineInputBorder(),
                                  filled: !_isManualCoordinate,
                                  fillColor: _isManualCoordinate ? inputFill : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                                ),
                                readOnly: !_isManualCoordinate,
                                onChanged: (_) => _syncFromUtm(),
                                validator: (val) => (val == null || double.tryParse(val.trim()) == null) ? 'Easting wajib angka' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _northingController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Northing (Y / Utara) *',
                                  hintText: '9434850.2',
                                  suffixText: 'm',
                                  prefixIcon: const Icon(Icons.north, size: 18),
                                  border: const OutlineInputBorder(),
                                  filled: !_isManualCoordinate,
                                  fillColor: _isManualCoordinate ? inputFill : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                                ),
                                readOnly: !_isManualCoordinate,
                                onChanged: (_) => _syncFromUtm(),
                                validator: (val) => (val == null || double.tryParse(val.trim()) == null) ? 'Northing wajib angka' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Pilihan Zona UTM (Default 50 untuk Sulsel)
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _utmZone,
                                decoration: InputDecoration(
                                  labelText: 'Zona UTM',
                                  prefixIcon: const Icon(Icons.grid_on, size: 18),
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: inputFill,
                                ),
                                items: List.generate(60, (i) => i + 1)
                                    .map((z) => DropdownMenuItem(value: z, child: Text('Zona $z${z == 50 ? ' (Makassar/Sulsel)' : ''}')))
                                    .toList(),
                                onChanged: _isManualCoordinate
                                    ? (val) {
                                        if (val != null) {
                                          setState(() => _utmZone = val);
                                          _syncFromUtm();
                                        }
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Pilihan Belahan Bumi (S / N)
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _utmHemisphere,
                                decoration: InputDecoration(
                                  labelText: 'Belahan Bumi',
                                  prefixIcon: const Icon(Icons.map, size: 18),
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: inputFill,
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'S', child: Text('S (Selatan/Sulsel)')),
                                  DropdownMenuItem(value: 'N', child: Text('N (Utara)')),
                                ],
                                onChanged: _isManualCoordinate
                                    ? (val) {
                                        if (val != null) {
                                          setState(() => _utmHemisphere = val);
                                          _syncFromUtm();
                                        }
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        if (_latController.text.isNotEmpty && _lonController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.purple.shade900.withValues(alpha: 0.3) : const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sync_alt, size: 15, color: Color(0xFF9333EA)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Ekuivalen WGS 84: Lat ${_latController.text}°, Lon ${_lonController.text}°',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFE9D5FF) : const Color(0xFF6B21A8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),

                      // Tombol Kunci Lokasi (GPS)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingLocation ? null : _ambilLokasi,
                          icon: _isLoadingLocation
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.gps_fixed),
                          label: Text(_isLoadingLocation ? 'Mengambil GPS Presisi...' : 'Kunci Lokasi (Sensor GPS)'),
                        ),
                      ),

                      // Jika tipe Line atau Polygon: tombol tambah titik ke list
                      if (_tipeGeometri != 'Point') ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            Text(
                              'Titik Tersusun (${_multiPoints.length}):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
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
                              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _multiPoints.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final pt = _multiPoints[i];
                                final utm = CoordinateConverter.latLonToUtm(pt['lat']!, pt['lng']!);
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.amber.shade700,
                                    child: Text('${i + 1}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text('${pt['lat']!.toStringAsFixed(6)}, ${pt['lng']!.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12)),
                                  subtitle: Text('UTM ${utm.zoneString}: X=${utm.easting.toStringAsFixed(0)}m, Y=${utm.northing.toStringAsFixed(0)}m', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

              // 4. Panel Foto Dokumentasi Lapangan
              Card(
                elevation: 0,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Text(
                            'Foto Dokumentasi Lapangan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
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
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _savedImagePath = null),
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                          label: const Text('Hapus Foto', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      ] else ...[
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, style: BorderStyle.solid),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey),
                              SizedBox(height: 6),
                              Text('Belum ada foto yang diambil', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
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
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Menyimpan ke Database...' : 'Simpan Data Survei',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
