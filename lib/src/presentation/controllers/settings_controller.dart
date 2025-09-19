import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  static const int minRecentSessions = 1;
  static const int maxRecentSessions = 20;

  int _recentSessionsCount = 10;
  bool _isLoading = true;

  int get recentSessionsCount => _recentSessionsCount;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _recentSessionsCount = await _dependencies.getRecentSessionsCount();

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
}
