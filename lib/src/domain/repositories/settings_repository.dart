abstract class SettingsRepository {
  Future<int> getRecentSessionsCount();
  Future<void> setRecentSessionsCount(int count);
}
