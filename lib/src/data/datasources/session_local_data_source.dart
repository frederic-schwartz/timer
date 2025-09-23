import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/timer_session_model.dart';

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
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime INTEGER NOT NULL,
        endTime INTEGER,
        totalPausedDuration INTEGER DEFAULT 0,
        isRunning INTEGER DEFAULT 1,
        isPaused INTEGER DEFAULT 0
      )
    ''');

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
    final result = await db.query(
      _tableName,
      where: 'isRunning = ?',
      whereArgs: [1],
      orderBy: 'startTime DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return TimerSessionModel.fromMap(result.first);
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
    final result = await db.query(
      _tableName,
      orderBy: 'startTime DESC',
    );

    return result.map(TimerSessionModel.fromMap).toList();
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
