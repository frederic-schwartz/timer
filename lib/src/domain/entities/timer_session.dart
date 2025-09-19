class TimerSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalPausedDuration; // in milliseconds
  final bool isRunning;
  final bool isPaused;

  const TimerSession({
    this.id,
    required this.startTime,
    this.endTime,
    this.totalPausedDuration = 0,
    this.isRunning = true,
    this.isPaused = false,
  });

  Duration get currentDuration {
    final now = DateTime.now();
    final end = endTime ?? now;
    final totalTime = end.difference(startTime).inMilliseconds;
    return Duration(milliseconds: totalTime - totalPausedDuration);
  }

  TimerSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? totalPausedDuration,
    bool? isRunning,
    bool? isPaused,
  }) {
    return TimerSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
