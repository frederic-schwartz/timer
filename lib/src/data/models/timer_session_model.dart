import '../../domain/entities/timer_session.dart';
import '../../domain/entities/category.dart';

class TimerSessionModel extends TimerSession {
  const TimerSessionModel({
    super.id,
    required super.startTime,
    super.endTime,
    super.totalPausedDuration,
    super.isRunning,
    super.isPaused,
    super.category,
    super.label,
  });

  factory TimerSessionModel.fromEntity(TimerSession session) {
    return TimerSessionModel(
      id: session.id,
      startTime: session.startTime,
      endTime: session.endTime,
      totalPausedDuration: session.totalPausedDuration,
      isRunning: session.isRunning,
      isPaused: session.isPaused,
      category: session.category,
      label: session.label,
    );
  }

  factory TimerSessionModel.fromMap(Map<String, dynamic> map, {Category? category}) {
    return TimerSessionModel(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : null,
      totalPausedDuration: map['totalPausedDuration'] as int? ?? 0,
      isRunning: (map['isRunning'] as int? ?? 0) == 1,
      isPaused: (map['isPaused'] as int? ?? 0) == 1,
      category: category,
      label: map['label'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'totalPausedDuration': totalPausedDuration,
      'isRunning': isRunning ? 1 : 0,
      'isPaused': isPaused ? 1 : 0,
      'categoryId': category?.id,
      'label': label,
    };
  }

  TimerSessionModel copyWithModel({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? totalPausedDuration,
    bool? isRunning,
    bool? isPaused,
    Category? category,
    String? label,
  }) {
    return TimerSessionModel(
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
