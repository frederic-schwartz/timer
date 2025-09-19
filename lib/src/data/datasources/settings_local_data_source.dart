import 'package:shared_preferences/shared_preferences.dart';

class SettingsLocalDataSource {
  static const String _recentSessionsCountKey = 'recent_sessions_count';
  static const int _defaultRecentSessionsCount = 10;

  Future<int> getRecentSessionsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_recentSessionsCountKey) ?? _defaultRecentSessionsCount;
  }

  Future<void> setRecentSessionsCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_recentSessionsCountKey, count);
  }
}
