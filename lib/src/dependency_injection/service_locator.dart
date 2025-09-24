import '../core/backup/icloud_backup_service.dart';
import '../data/datasources/category_local_data_source.dart';
import '../data/datasources/session_local_data_source.dart';
import '../data/datasources/settings_local_data_source.dart';
import '../data/datasources/timer_local_data_source.dart';
import '../data/repositories/category_repository_impl.dart';
import '../data/repositories/session_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/timer_repository_impl.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/timer_repository.dart';
import '../domain/usecases/backup_app_data.dart';
import '../domain/usecases/clear_completed_sessions.dart';
import '../domain/usecases/delete_category.dart';
import '../domain/usecases/delete_session.dart';
import '../domain/usecases/get_all_categories.dart';
import '../domain/usecases/get_all_sessions.dart';
import '../domain/usecases/get_category_by_id.dart';
import '../domain/usecases/get_recent_sessions_count.dart';
import '../domain/usecases/get_timer_snapshot.dart';
import '../domain/usecases/initialize_timer.dart';
import '../domain/usecases/insert_category.dart';
import '../domain/usecases/pause_timer.dart';
import '../domain/usecases/reset_timer.dart';
import '../domain/usecases/set_recent_sessions_count.dart';
import '../domain/usecases/start_timer.dart';
import '../domain/usecases/stop_timer.dart';
import '../domain/usecases/update_category.dart';
import '../domain/usecases/update_current_session.dart';
import '../domain/usecases/update_session.dart';
import '../domain/usecases/watch_timer_duration.dart';
import '../domain/usecases/watch_timer_state.dart';

class AppDependencies {
  AppDependencies._() {
    _configure();
  }

  static final AppDependencies instance = AppDependencies._();

  late final CategoryLocalDataSource _categoryLocalDataSource;
  late final SessionLocalDataSource _sessionLocalDataSource;
  late final TimerLocalDataSource _timerLocalDataSource;
  late final SettingsLocalDataSource _settingsLocalDataSource;
  late final ICloudBackupService _icloudBackupService;

  late final CategoryRepository categoryRepository;
  late final SessionRepository sessionRepository;
  late final TimerRepository timerRepository;
  late final SettingsRepository settingsRepository;

  late final InitializeTimer initializeTimer;
  late final StartTimer startTimer;
  late final PauseTimer pauseTimer;
  late final StopTimer stopTimer;
  late final ResetTimer resetTimer;
  late final UpdateCurrentSession updateCurrentSession;
  late final WatchTimerDuration watchTimerDuration;
  late final WatchTimerState watchTimerState;
  late final GetTimerSnapshot getTimerSnapshot;

  late final GetAllSessions getAllSessions;
  late final UpdateSession updateSession;
  late final DeleteSession deleteSession;
  late final ClearCompletedSessions clearCompletedSessions;

  late final GetRecentSessionsCount getRecentSessionsCount;
  late final SetRecentSessionsCount setRecentSessionsCount;

  late final GetAllCategories getAllCategories;
  late final InsertCategory insertCategory;
  late final UpdateCategory updateCategory;
  late final DeleteCategory deleteCategory;
  late final GetCategoryById getCategoryById;
  late final BackupAppData backupAppData;

  void _configure() {
    _categoryLocalDataSource = CategoryLocalDataSource();
    _sessionLocalDataSource = SessionLocalDataSource();
    _settingsLocalDataSource = SettingsLocalDataSource();
    _timerLocalDataSource = TimerLocalDataSource(_sessionLocalDataSource);
    _icloudBackupService = ICloudBackupService();

    categoryRepository = CategoryRepositoryImpl(_categoryLocalDataSource);
    sessionRepository = SessionRepositoryImpl(_sessionLocalDataSource);
    timerRepository = TimerRepositoryImpl(_timerLocalDataSource);
    settingsRepository = SettingsRepositoryImpl(_settingsLocalDataSource);

    initializeTimer = InitializeTimer(timerRepository);
    startTimer = StartTimer(timerRepository);
    pauseTimer = PauseTimer(timerRepository);
    stopTimer = StopTimer(timerRepository);
    resetTimer = ResetTimer(timerRepository);
    updateCurrentSession = UpdateCurrentSession(timerRepository);
    watchTimerDuration = WatchTimerDuration(timerRepository);
    watchTimerState = WatchTimerState(timerRepository);
    getTimerSnapshot = GetTimerSnapshot(timerRepository);

    getAllSessions = GetAllSessions(sessionRepository);
    updateSession = UpdateSession(sessionRepository);
    deleteSession = DeleteSession(sessionRepository);
    clearCompletedSessions = ClearCompletedSessions(sessionRepository);

    getRecentSessionsCount = GetRecentSessionsCount(settingsRepository);
    setRecentSessionsCount = SetRecentSessionsCount(settingsRepository);

    getAllCategories = GetAllCategories(categoryRepository);
    insertCategory = InsertCategory(categoryRepository);
    updateCategory = UpdateCategory(categoryRepository);
    deleteCategory = DeleteCategory(categoryRepository);
    getCategoryById = GetCategoryById(categoryRepository);

    backupAppData = BackupAppData(
      sessionRepository,
      categoryRepository,
      settingsRepository,
      _icloudBackupService,
    );
  }

  void dispose() {
    timerRepository.dispose();
  }
}
