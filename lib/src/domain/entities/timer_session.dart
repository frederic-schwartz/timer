import 'category.dart';

class TimerSession {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int totalPauseDuration; // in milliseconds - durée totale de pause
  final bool isPaused;
  final Category? category;
  final String? label;

  const TimerSession({
    this.id,
    required this.startedAt,
    this.endedAt,
    this.totalPauseDuration = 0,
    this.isPaused = false,
    this.category,
    this.label,
  });

  bool get isRunning => endedAt == null && !isPaused;

  Duration get totalDuration {
    final end = endedAt ?? DateTime.now();
    final duration = end.difference(startedAt);
    final pauseDuration = Duration(milliseconds: totalPauseDuration);
    return duration - pauseDuration;
  }

  Duration get grossDuration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  Duration get pauseDuration {
    return Duration(milliseconds: totalPauseDuration);
  }

  TimerSession copyWith({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? totalPauseDuration,
    bool? isPaused,
    Category? category,
    String? label,
  }) {
    return TimerSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalPauseDuration: totalPauseDuration ?? this.totalPauseDuration,
      isPaused: isPaused ?? this.isPaused,
      category: category ?? this.category,
      label: label ?? this.label,
    );
  }
}
