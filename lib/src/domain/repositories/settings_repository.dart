abstract class SettingsRepository {
  Future<int> getRecentSessionsCount();
  Future<void> setRecentSessionsCount(int count);
  Future<bool> getWakeLockEnabled();
  Future<void> setWakeLockEnabled(bool enabled);
}
