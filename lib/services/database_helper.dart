import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/fatwa.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fatwas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fatwas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fileName TEXT NOT NULL,
        filePath TEXT,
        title TEXT,
        category TEXT,
        transcription TEXT,
        status INTEGER NOT NULL DEFAULT 0,
        errorMessage TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE fatwas ADD COLUMN title TEXT');
      await db.execute('ALTER TABLE fatwas ADD COLUMN category TEXT');
    }
  }

  Future<int> insertFatwa(Fatwa fatwa) async {
    final db = await database;
    return await db.insert('fatwas', fatwa.toMap());
  }

  Future<List<Fatwa>> getAllFatwas() async {
    final db = await database;
    final maps = await db.query('fatwas', orderBy: 'createdAt DESC');
    return maps.map((map) => Fatwa.fromMap(map)).toList();
  }

  Future<List<Fatwa>> searchFatwas(String query) async {
    final db = await database;
    final maps = await db.query(
      'fatwas',
      where: 'transcription LIKE ? OR title LIKE ? OR fileName LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Fatwa.fromMap(map)).toList();
  }

  Future<Fatwa?> getFatwa(int id) async {
    final db = await database;
    final maps = await db.query('fatwas', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Fatwa.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateFatwa(Fatwa fatwa) async {
    final db = await database;
    return await db.update(
      'fatwas',
      fatwa.toMap(),
      where: 'id = ?',
      whereArgs: [fatwa.id],
    );
  }

  Future<int> deleteFatwa(int id) async {
    final db = await database;
    return await db.delete('fatwas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllFatwas() async {
    final db = await database;
    return await db.delete('fatwas');
  }
}
