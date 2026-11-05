import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/survey_point.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Fallback penyimpanan data di memori jika dijalankan di Web (Chrome) / Desktop Windows
  final List<SurveyPoint> _memoryStore = [];
  int _nextId = 1;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDB('survey_gis_v2.db');
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
      version: 2,
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
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE survey_points ADD COLUMN tipeGeometri TEXT NOT NULL DEFAULT 'Point'");
        await db.execute("ALTER TABLE survey_points ADD COLUMN koordinatList TEXT");
      } catch (_) {}
    }
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

  // Menghapus data survei berdasarkan ID
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

  Future<void> close() async {
    final db = await database;
    if (db != null) {
      await db.close();
    }
  }
}
