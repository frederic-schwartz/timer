import 'category.dart';

class TimerSession {
  final int? id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalDuration; // in milliseconds - durée totale accumulée
  final int totalPausedDuration; // in milliseconds
  final bool isRunning;
  final bool isPaused;
  final Category? category;
  final String? label;

  const TimerSession({
    this.id,
    required this.createdAt,
    DateTime? updatedAt,
    this.totalDuration = 0,
    this.totalPausedDuration = 0,
    this.isRunning = true,
    this.isPaused = false,
    this.category,
    this.label,
  }) : updatedAt = updatedAt ?? createdAt;

  Duration get currentDuration {
    return Duration(milliseconds: totalDuration);
  }

  TimerSession copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalDuration,
    int? totalPausedDuration,
    bool? isRunning,
    bool? isPaused,
    Category? category,
    String? label,
  }) {
    return TimerSession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalDuration: totalDuration ?? this.totalDuration,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      category: category ?? this.category,
      label: label ?? this.label,
    );
  }
}
