import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _recentSessionsCountKey = 'recent_sessions_count';
  static const int _defaultRecentSessionsCount = 10;

  static Future<int> getRecentSessionsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_recentSessionsCountKey) ?? _defaultRecentSessionsCount;
  }

  static Future<void> setRecentSessionsCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_recentSessionsCountKey, count);
  }
}