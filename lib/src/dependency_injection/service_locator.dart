import '../data/datasources/session_local_data_source.dart';
import '../data/datasources/settings_local_data_source.dart';
import '../data/datasources/timer_local_data_source.dart';
import '../data/repositories/session_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/timer_repository_impl.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/timer_repository.dart';
import '../domain/usecases/clear_completed_sessions.dart';
import '../domain/usecases/delete_session.dart';
import '../domain/usecases/get_all_sessions.dart';
import '../domain/usecases/get_recent_sessions_count.dart';
import '../domain/usecases/get_timer_snapshot.dart';
import '../domain/usecases/initialize_timer.dart';
import '../domain/usecases/pause_timer.dart';
import '../domain/usecases/resume_session.dart';
import '../domain/usecases/set_recent_sessions_count.dart';
import '../domain/usecases/start_timer.dart';
import '../domain/usecases/stop_timer.dart';
import '../domain/usecases/watch_timer_duration.dart';
import '../domain/usecases/watch_timer_state.dart';

class AppDependencies {
  AppDependencies._() {
    _configure();
  }

  static final AppDependencies instance = AppDependencies._();

  late final SessionLocalDataSource _sessionLocalDataSource;
  late final TimerLocalDataSource _timerLocalDataSource;
  late final SettingsLocalDataSource _settingsLocalDataSource;

  late final SessionRepository sessionRepository;
  late final TimerRepository timerRepository;
  late final SettingsRepository settingsRepository;

  late final InitializeTimer initializeTimer;
  late final StartTimer startTimer;
  late final PauseTimer pauseTimer;
  late final StopTimer stopTimer;
  late final ResumeSession resumeSession;
  late final WatchTimerDuration watchTimerDuration;
  late final WatchTimerState watchTimerState;
  late final GetTimerSnapshot getTimerSnapshot;

  late final GetAllSessions getAllSessions;
  late final DeleteSession deleteSession;
  late final ClearCompletedSessions clearCompletedSessions;

  late final GetRecentSessionsCount getRecentSessionsCount;
  late final SetRecentSessionsCount setRecentSessionsCount;

  void _configure() {
    _sessionLocalDataSource = SessionLocalDataSource();
    _settingsLocalDataSource = SettingsLocalDataSource();
    _timerLocalDataSource = TimerLocalDataSource(_sessionLocalDataSource);

    sessionRepository = SessionRepositoryImpl(_sessionLocalDataSource);
    timerRepository = TimerRepositoryImpl(_timerLocalDataSource);
    settingsRepository = SettingsRepositoryImpl(_settingsLocalDataSource);

    initializeTimer = InitializeTimer(timerRepository);
    startTimer = StartTimer(timerRepository);
    pauseTimer = PauseTimer(timerRepository);
    stopTimer = StopTimer(timerRepository);
    resumeSession = ResumeSession(timerRepository);
    watchTimerDuration = WatchTimerDuration(timerRepository);
    watchTimerState = WatchTimerState(timerRepository);
    getTimerSnapshot = GetTimerSnapshot(timerRepository);

    getAllSessions = GetAllSessions(sessionRepository);
    deleteSession = DeleteSession(sessionRepository);
    clearCompletedSessions = ClearCompletedSessions(sessionRepository);

    getRecentSessionsCount = GetRecentSessionsCount(settingsRepository);
    setRecentSessionsCount = SetRecentSessionsCount(settingsRepository);
  }

  void dispose() {
    timerRepository.dispose();
  }
}
