import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/session_log_model.dart';
import '../models/timer_session_model.dart';

class SessionLocalDataSource {
  SessionLocalDataSource();

  static const String _tableName = 'timer_sessions';
  static const String _logsTableName = 'session_logs';

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
      version: 3,
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

    await db.execute('''
      CREATE TABLE $_logsTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER,
        timestamp INTEGER NOT NULL,
        action TEXT NOT NULL,
        details TEXT,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (sessionId) REFERENCES $_tableName (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $_logsTableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId INTEGER,
          timestamp INTEGER NOT NULL,
          action TEXT NOT NULL,
          details TEXT,
          latitude REAL,
          longitude REAL,
          FOREIGN KEY (sessionId) REFERENCES $_tableName (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $_logsTableName ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE $_logsTableName ADD COLUMN longitude REAL');
    }
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

  Future<int> insertSessionLog(SessionLogModel log) async {
    final db = await _db;
    return db.insert(_logsTableName, log.toMap());
  }

  Future<List<SessionLogModel>> getSessionLogs(int sessionId) async {
    final db = await _db;
    final result = await db.query(
      _logsTableName,
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return result.map(SessionLogModel.fromMap).toList();
  }

  Future<List<SessionLogModel>> getAllLogs() async {
    final db = await _db;
    final result = await db.query(
      _logsTableName,
      orderBy: 'timestamp DESC',
    );

    return result.map(SessionLogModel.fromMap).toList();
  }

  Future<void> deleteSessionLogs(int sessionId) async {
    final db = await _db;
    await db.delete(
      _logsTableName,
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteAllLogs() async {
    final db = await _db;
    await db.delete(_logsTableName);
  }
}
