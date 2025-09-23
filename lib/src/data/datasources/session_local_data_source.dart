import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/timer_session_model.dart';
import '../models/category_model.dart';

class SessionLocalDataSource {
  SessionLocalDataSource();

  static const String _tableName = 'timer_sessions';

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'timer.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        totalDuration INTEGER DEFAULT 0,
        totalPausedDuration INTEGER DEFAULT 0,
        isRunning INTEGER DEFAULT 1,
        isPaused INTEGER DEFAULT 0,
        categoryId INTEGER,
        label TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Insert default categories
    await db.insert('categories', {'name': 'Travail', 'color': '#2196F3'});
    await db.insert('categories', {'name': 'Personnel', 'color': '#4CAF50'});
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // No upgrades needed for version 1
  }

  Future<int> insertSession(TimerSessionModel session) async {
    final db = await _db;
    return db.insert(_tableName, session.toMap());
  }

  Future<TimerSessionModel?> getCurrentSession() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT s.*, c.name as category_name, c.color as category_color
      FROM $_tableName s
      LEFT JOIN categories c ON s.categoryId = c.id
      WHERE s.isRunning = ?
      ORDER BY s.updatedAt DESC
      LIMIT 1
    ''', [1]);

    if (result.isNotEmpty) {
      final row = result.first;
      CategoryModel? category;
      if (row['categoryId'] != null) {
        category = CategoryModel(
          id: row['categoryId'] as int,
          name: row['category_name'] as String,
          color: row['category_color'] as String,
        );
      }
      return TimerSessionModel.fromMap(row, category: category);
    }
    return null;
  }

  Future<void> updateSession(TimerSessionModel session) async {
    if (session.id == null) {
      throw ArgumentError('Cannot update a session without an id');
    }

    final db = await _db;
    await db.update(
      _tableName,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<TimerSessionModel>> getAllSessions() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT s.*, c.name as category_name, c.color as category_color
      FROM $_tableName s
      LEFT JOIN categories c ON s.categoryId = c.id
      ORDER BY s.updatedAt DESC
    ''');

    return result.map((row) {
      CategoryModel? category;
      if (row['categoryId'] != null) {
        category = CategoryModel(
          id: row['categoryId'] as int,
          name: row['category_name'] as String,
          color: row['category_color'] as String,
        );
      }
      return TimerSessionModel.fromMap(row, category: category);
    }).toList();
  }

  Future<void> deleteSession(int id) async {
    final db = await _db;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}
