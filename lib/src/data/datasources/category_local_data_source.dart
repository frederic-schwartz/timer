import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category_model.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource();

  static const String _tableName = 'categories';

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Force l'initialisation de la base de données
  Future<void> ensureInitialized() async {
    await _db;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'timer.db');

    return openDatabase(
      path,
      version: 1,
    );
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _db;
    final result = await db.query(
      _tableName,
      orderBy: 'name ASC',
    );

    return result.map(CategoryModel.fromMap).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await _db;
    return db.insert(_tableName, category.toMap());
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (category.id == null) {
      throw ArgumentError('Cannot update a category without an id');
    }

    final db = await _db;
    await db.update(
      _tableName,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await _db;

    // First, set sessions with this category to null
    await db.update(
      'timer_sessions',
      {'categoryId': null},
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );

    // Then delete the category
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await _db;
    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return CategoryModel.fromMap(result.first);
    }
    return null;
  }
}