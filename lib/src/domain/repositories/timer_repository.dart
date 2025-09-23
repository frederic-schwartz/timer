import 'dart:async';

import '../entities/category.dart';
import '../entities/timer_session.dart';
import '../entities/timer_snapshot.dart';
import '../entities/timer_state.dart';

abstract class TimerRepository {
  Stream<Duration> watchDuration();
  Stream<TimerState> watchState();

  Duration get currentDuration;
  TimerState get currentState;

  TimerSnapshot snapshot();
  TimerSession? get currentSession;

  Future<void> initialize();
  Future<void> startTimer({Category? category, String? label});
  Future<void> pauseTimer();
  Future<void> stopTimer();
  Future<void> reset();
  Future<void> updateCurrentSession({
    DateTime? startedAt,
    DateTime? endedAt,
    int? totalPauseDuration,
    Category? category,
    String? label,
  });
  void dispose();
}
