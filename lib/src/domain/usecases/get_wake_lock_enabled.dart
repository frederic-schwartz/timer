import '../repositories/settings_repository.dart';

class GetWakeLockEnabled {
  final SettingsRepository _settingsRepository;

  GetWakeLockEnabled(this._settingsRepository);

  Future<bool> call() => _settingsRepository.getWakeLockEnabled();
}