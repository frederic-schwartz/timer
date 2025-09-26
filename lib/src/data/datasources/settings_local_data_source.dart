import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalDataSource {
  static const String _recentSessionsCountKey = 'recent_sessions_count';
  static const String _wakeLockEnabledKey = 'wake_lock_enabled';
  static const int _defaultRecentSessionsCount = 10;
  static const bool _defaultWakeLockEnabled = false;

  Future<int> getRecentSessionsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_recentSessionsCountKey) ?? _defaultRecentSessionsCount;
  }

  Future<void> setRecentSessionsCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_recentSessionsCountKey, count);
  }

  Future<bool> getWakeLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wakeLockEnabledKey) ?? _defaultWakeLockEnabled;
  }

  Future<void> setWakeLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wakeLockEnabledKey, enabled);
  }
}
