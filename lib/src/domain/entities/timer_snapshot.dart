import 'timer_state.dart';

class TimerSnapshot {
  final Duration currentDuration;
  final TimerState state;
  final Duration totalPausedDuration;
  final Duration totalPausedDurationRealTime;
  final Duration currentPauseDuration;

  const TimerSnapshot({
    required this.currentDuration,
    required this.state,
    required this.totalPausedDuration,
    required this.totalPausedDurationRealTime,
    required this.currentPauseDuration,
  });
}
