import 'dart:async';

import '../entities/timer_session.dart';
import '../entities/timer_snapshot.dart';
import '../entities/timer_state.dart';

abstract class TimerRepository {
  Stream<Duration> watchDuration();
  Stream<TimerState> watchState();

  Duration get currentDuration;
  TimerState get currentState;
  Duration get totalPausedDuration;
  Duration get totalPausedDurationRealTime;
  Duration get currentPauseDuration;

  TimerSnapshot snapshot();

  Future<void> initialize();
  Future<void> startTimer();
  Future<void> pauseTimer();
  Future<void> stopTimer();
  Future<void> reset();
  Future<void> resumeSession(TimerSession session);
  void dispose();
}
