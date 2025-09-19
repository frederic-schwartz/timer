import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/timer_session.dart';
import '../models/session_log.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'timer_sessions';
  static const String _logsTableName = 'session_logs';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'timer.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    // Create sessions table
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

    // Create logs table
    await db.execute('''
      CREATE TABLE $_logsTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER,
        timestamp INTEGER NOT NULL,
        action TEXT NOT NULL,
        details TEXT,
        FOREIGN KEY (sessionId) REFERENCES $_tableName (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add logs table for existing databases
      await db.execute('''
        CREATE TABLE $_logsTableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId INTEGER,
          timestamp INTEGER NOT NULL,
          action TEXT NOT NULL,
          details TEXT,
          FOREIGN KEY (sessionId) REFERENCES $_tableName (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  static Future<int> insertSession(TimerSession session) async {
    final db = await database;
    return await db.insert(_tableName, session.toMap());
  }

  static Future<TimerSession?> getCurrentSession() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'isRunning = ?',
      whereArgs: [1],
      orderBy: 'startTime DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return TimerSession.fromMap(result.first);
    }
    return null;
  }

  static Future<void> updateSession(TimerSession session) async {
    final db = await database;
    await db.update(
      _tableName,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  static Future<List<TimerSession>> getAllSessions() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      orderBy: 'startTime DESC',
    );

    return result.map((map) => TimerSession.fromMap(map)).toList();
  }

  static Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Session logs methods
  static Future<int> insertSessionLog(SessionLog log) async {
    final db = await database;
    return await db.insert(_logsTableName, log.toMap());
  }

  static Future<List<SessionLog>> getSessionLogs(int sessionId) async {
    final db = await database;
    final result = await db.query(
      _logsTableName,
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return result.map((map) => SessionLog.fromMap(map)).toList();
  }

  static Future<List<SessionLog>> getAllLogs() async {
    final db = await database;
    final result = await db.query(
      _logsTableName,
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => SessionLog.fromMap(map)).toList();
  }

  static Future<void> deleteSessionLogs(int sessionId) async {
    final db = await database;
    await db.delete(
      _logsTableName,
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
  }

  static Future<void> deleteAllLogs() async {
    final db = await database;
    await db.delete(_logsTableName);
  }
}