import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/timer_session.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'timer_sessions';

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
      version: 1,
      onCreate: _createDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
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
}