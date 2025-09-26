import '../repositories/settings_repository.dart';

class SetWakeLockEnabled {
  final SettingsRepository _settingsRepository;

  SetWakeLockEnabled(this._settingsRepository);

  Future<void> call(bool enabled) => _settingsRepository.setWakeLockEnabled(enabled);
}