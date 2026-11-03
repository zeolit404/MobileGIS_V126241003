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
    if (kIsWeb) return null; // Web tidak memakai sqflite native
    if (_database != null) return _database!;
    try {
      _database = await _initDB('survey_gis.db');
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
      version: 1,
      onCreate: _createDB,
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
        waktu TEXT NOT NULL
      )
    ''');
  }

  // Menyimpan titik survei baru
  Future<int> insertSurvey(SurveyPoint point) async {
    final db = await database;
    if (db != null) {
      return await db.insert('survey_points', point.toMap()..remove('id'));
    } else {
      // Penyimpanan Fallback untuk Chrome Web / Windows Preview
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
      // Mengambil dari memory store jika dijalankan di Web Chrome
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

  // Menutup database
  Future<void> close() async {
    final db = await database;
    if (db != null) {
      await db.close();
    }
  }
}
