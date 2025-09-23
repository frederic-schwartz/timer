import 'category.dart';

class TimerSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalPausedDuration; // in milliseconds
  final bool isRunning;
  final bool isPaused;
  final Category? category;
  final String? label;

  const TimerSession({
    this.id,
    required this.startTime,
    this.endTime,
    this.totalPausedDuration = 0,
    this.isRunning = true,
    this.isPaused = false,
    this.category,
    this.label,
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
    Category? category,
    String? label,
  }) {
    return TimerSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      category: category ?? this.category,
      label: label ?? this.label,
    );
  }
}
