import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<int> getRecentSessionsCount() => _localDataSource.getRecentSessionsCount();

  @override
  Future<void> setRecentSessionsCount(int count) => _localDataSource.setRecentSessionsCount(count);
}
