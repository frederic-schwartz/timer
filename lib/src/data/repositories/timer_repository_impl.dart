import '../../domain/entities/category.dart';
import '../../domain/entities/timer_session.dart';
import '../../domain/entities/timer_snapshot.dart';
import '../../domain/entities/timer_state.dart';
import '../../domain/repositories/timer_repository.dart';
import '../datasources/timer_local_data_source.dart';
import '../models/timer_session_model.dart';

class TimerRepositoryImpl implements TimerRepository {
  TimerRepositoryImpl(this._timerLocalDataSource);

  final TimerLocalDataSource _timerLocalDataSource;

  @override
  Stream<Duration> watchDuration() => _timerLocalDataSource.durationStream;

  @override
  Stream<TimerState> watchState() => _timerLocalDataSource.stateStream;

  @override
  Duration get currentDuration => _timerLocalDataSource.currentDuration;

  @override
  TimerState get currentState => _timerLocalDataSource.currentState;

  @override
  Duration get currentPauseDuration => _timerLocalDataSource.currentPauseDuration;

  @override
  Duration get totalPausedDuration => _timerLocalDataSource.totalPausedDuration;

  @override
  Duration get totalPausedDurationRealTime => _timerLocalDataSource.totalPausedDurationRealTime;

  @override
  Future<void> initialize() => _timerLocalDataSource.initialize();

  @override
  Future<void> startTimer({Category? category, String? label}) =>
      _timerLocalDataSource.startTimer(category: category, label: label);

  @override
  Future<void> pauseTimer() => _timerLocalDataSource.pauseTimer();

  @override
  Future<void> stopTimer() => _timerLocalDataSource.stopTimer();

  @override
  Future<void> reset() => _timerLocalDataSource.reset();

  @override
  Future<void> resumeSession(TimerSession session) {
    final model = TimerSessionModel.fromEntity(session);
    return _timerLocalDataSource.resumeSession(model);
  }

  @override
  TimerSnapshot snapshot() {
    return TimerSnapshot(
      currentDuration: _timerLocalDataSource.currentDuration,
      state: _timerLocalDataSource.currentState,
      totalPausedDuration: _timerLocalDataSource.totalPausedDuration,
      totalPausedDurationRealTime: _timerLocalDataSource.totalPausedDurationRealTime,
      currentPauseDuration: _timerLocalDataSource.currentPauseDuration,
    );
  }

  @override
  void dispose() {
    _timerLocalDataSource.dispose();
  }
}
