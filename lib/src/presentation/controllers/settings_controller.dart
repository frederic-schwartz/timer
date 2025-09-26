import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/category.dart' as entities;

class SettingsController extends ChangeNotifier {
  SettingsController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  static const int minRecentSessions = 1;
  static const int maxRecentSessions = 20;

  int _recentSessionsCount = 10;
  bool _isLoading = true;
  bool _wakeLockEnabled = false;
  List<entities.Category> _categories = const [];

  int get recentSessionsCount => _recentSessionsCount;
  bool get isLoading => _isLoading;
  bool get wakeLockEnabled => _wakeLockEnabled;
  List<entities.Category> get categories => _categories;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _recentSessionsCount = await _dependencies.getRecentSessionsCount();
    _wakeLockEnabled = await _dependencies.getWakeLockEnabled();
    await _loadCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> decreaseRecentSessions() async {
    if (_recentSessionsCount <= minRecentSessions) return;
    _recentSessionsCount--;
    notifyListeners();
    await _dependencies.setRecentSessionsCount(_recentSessionsCount);
  }

  Future<void> increaseRecentSessions() async {
    if (_recentSessionsCount >= maxRecentSessions) return;
    _recentSessionsCount++;
    notifyListeners();
    await _dependencies.setRecentSessionsCount(_recentSessionsCount);
  }

  Future<void> clearCompletedSessions() async {
    await _dependencies.clearCompletedSessions();
  }

  Future<void> backupToICloud() async {
    await _dependencies.backupAppData();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _dependencies.getAllCategories();
    } catch (_) {
      _categories = const [];
    }
  }

  Future<void> addCategory(String name, String color) async {
    try {
      final category = entities.Category(name: name, color: color);
      await _dependencies.insertCategory(category);
      await _loadCategories();
      notifyListeners();
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  Future<void> updateCategory(entities.Category category) async {
    try {
      await _dependencies.updateCategory(category);
      await _loadCategories();
      notifyListeners();
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await _dependencies.deleteCategory(categoryId);
      await _loadCategories();
      notifyListeners();
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  Future<void> setWakeLockEnabled(bool enabled) async {
    try {
      _wakeLockEnabled = enabled;
      notifyListeners();
      await _dependencies.setWakeLockEnabled(enabled);
      if (kDebugMode) {
        print('🔒 Wake lock setting saved: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔒 Error saving wake lock setting: $e');
      }
      // En cas d'erreur, rétablir l'état précédent
      _wakeLockEnabled = !enabled;
      notifyListeners();
    }
  }
}
