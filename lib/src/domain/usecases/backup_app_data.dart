import '../../core/backup/icloud_backup_service.dart';
import '../entities/category.dart';
import '../entities/timer_session.dart';
import '../repositories/category_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';

class BackupAppData {
  BackupAppData(
    this._sessionRepository,
    this._categoryRepository,
    this._settingsRepository,
    this._icloudBackupService,
  );

  final SessionRepository _sessionRepository;
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final ICloudBackupService _icloudBackupService;

  Future<void> call() async {
    final sessions = await _sessionRepository.getAllSessions();
    final categories = await _categoryRepository.getAllCategories();
    final recentSessionsCount = await _settingsRepository.getRecentSessionsCount();

    final payload = {
      'version': 1,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': {
        'recentSessionsCount': recentSessionsCount,
      },
      'categories': categories.map(_categoryToMap).toList(),
      'sessions': sessions.map(_sessionToMap).toList(),
    };

    await _icloudBackupService.saveBackup(payload);
  }

  Map<String, dynamic> _categoryToMap(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'color': category.color,
    };
  }

  Map<String, dynamic> _sessionToMap(TimerSession session) {
    return {
      'id': session.id,
      'startedAt': session.startedAt.toUtc().toIso8601String(),
      'endedAt': session.endedAt?.toUtc().toIso8601String(),
      'totalPauseDuration': session.totalPauseDuration,
      'isPaused': session.isPaused,
      'categoryId': session.category?.id,
      'categoryName': session.category?.name,
      'categoryColor': session.category?.color,
      'label': session.label,
    };
  }
}
