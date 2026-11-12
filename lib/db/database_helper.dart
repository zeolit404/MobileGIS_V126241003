import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/digitization_result.dart';
import '../models/survey_point.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Fallback penyimpanan data di memori jika dijalankan di Web (Chrome) / Desktop Windows
  final List<SurveyPoint> _memoryStore = [];
  final List<DigitizationResult> _digitizationMemoryStore = [];
  int _nextId = 1;
  int _nextDigitizationId = 1;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('survey_gis_v3.db');
      return _database;
    } catch (e) {
      debugPrint('SQLite native tidak tersedia, beralih ke memory store: $e');
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE survey_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        kategori TEXT NOT NULL,
        keterangan TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        fotoPath TEXT,
        waktu TEXT NOT NULL,
        tipeGeometri TEXT NOT NULL DEFAULT 'Point',
        koordinatList TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS digitization_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        distance_meters REAL NOT NULL,
        vertex_count INTEGER NOT NULL,
        waktu TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    final cols = await db.rawQuery('PRAGMA table_info(survey_points)');
    final names = cols.map((c) => c['name'] as String).toSet();

    if (!names.contains('tipeGeometri')) {
      await db.execute("ALTER TABLE survey_points ADD COLUMN tipeGeometri TEXT NOT NULL DEFAULT 'Point'");
    }
    if (!names.contains('koordinatList')) {
      await db.execute("ALTER TABLE survey_points ADD COLUMN koordinatList TEXT");
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS digitization_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        distance_meters REAL NOT NULL,
        vertex_count INTEGER NOT NULL,
        waktu TEXT NOT NULL
      )
    ''');
  }

  // Menyimpan titik/garis/polygon survei baru
  Future<int> insertSurvey(SurveyPoint point) async {
    final db = await database;
    if (db != null) {
      return await db.insert('survey_points', point.toMap()..remove('id'));
    } else {
      final assignedId = _nextId++;
      final pointWithId = SurveyPoint(
        id: assignedId,
        nama: point.nama,
        kategori: point.kategori,
        keterangan: point.keterangan,
        latitude: point.latitude,
        longitude: point.longitude,
        fotoPath: point.fotoPath,
        waktu: point.waktu,
        tipeGeometri: point.tipeGeometri,
        koordinatList: point.koordinatList,
      );
      _memoryStore.insert(0, pointWithId);
      return assignedId;
    }
  }

  // Alias kompatibilitas
  Future<int> insertSurveyPoint(SurveyPoint point) => insertSurvey(point);

  // Mengambil seluruh data survei tersimpan
  Future<List<SurveyPoint>> getAllSurveys() async {
    final db = await database;
    if (db != null) {
      final result = await db.query(
        'survey_points',
        orderBy: 'id DESC',
      );
      return result.map((json) => SurveyPoint.fromMap(json)).toList();
    } else {
      return List<SurveyPoint>.from(_memoryStore);
    }
  }

  // Alias kompatibilitas
  Future<List<SurveyPoint>> getAllSurveyPoints() => getAllSurveys();

  // Menghapus titik survei berdasarkan ID
  Future<int> deleteSurvey(int id) async {
    final db = await database;
    if (db != null) {
      return await db.delete(
        'survey_points',
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      _memoryStore.removeWhere((item) => item.id == id);
      return 1;
    }
  }

  // Menghapus semua titik survei
  Future<int> deleteAllSurveys() async {
    final db = await database;
    if (db != null) {
      return await db.delete('survey_points');
    } else {
      final count = _memoryStore.length;
      _memoryStore.clear();
      return count;
    }
  }

  // ---------------- Digitization Results (Line/Polygon screenshot store) ----------------
  Future<int> insertDigitizationResult(DigitizationResult result) async {
    final db = await database;
    if (db != null) {
      return await db.insert('digitization_results', result.toMap()..remove('id'));
    } else {
      final id = _nextDigitizationId++;
      final withId = DigitizationResult(
        id: id,
        imagePath: result.imagePath,
        distanceMeters: result.distanceMeters,
        vertexCount: result.vertexCount,
        waktu: result.waktu,
      );
      _digitizationMemoryStore.insert(0, withId);
      return id;
    }
  }

  Future<List<DigitizationResult>> getAllDigitizationResults() async {
    final db = await database;
    if (db != null) {
      final result = await db.query('digitization_results', orderBy: 'id DESC');
      return result.map((json) => DigitizationResult.fromMap(json)).toList();
    } else {
      return List<DigitizationResult>.from(_digitizationMemoryStore);
    }
  }
}
