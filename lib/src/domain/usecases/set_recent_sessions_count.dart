import '../repositories/settings_repository.dart';

class SetRecentSessionsCount {
  SetRecentSessionsCount(this._repository);

  final SettingsRepository _repository;

  Future<void> call(int count) => _repository.setRecentSessionsCount(count);
}
