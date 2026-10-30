import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/survey_point.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('survey_gis.db');
    return _database!;
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
    final db = await instance.database;
    return await db.insert('survey_points', point.toMap());
  }

  // Mengambil seluruh data survei tersimpan
  Future<List<SurveyPoint>> getAllSurveys() async {
    final db = await instance.database;
    final result = await db.query(
      'survey_points',
      orderBy: 'id DESC',
    );
    return result.map((json) => SurveyPoint.fromMap(json)).toList();
  }

  // Menghapus data survei berdasarkan ID
  Future<int> deleteSurvey(int id) async {
    final db = await instance.database;
    return await db.delete(
      'survey_points',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Menutup database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
