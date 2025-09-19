import '../repositories/settings_repository.dart';

class GetRecentSessionsCount {
  GetRecentSessionsCount(this._repository);

  final SettingsRepository _repository;

  Future<int> call() => _repository.getRecentSessionsCount();
}
