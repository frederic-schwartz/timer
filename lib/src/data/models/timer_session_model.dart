import '../../domain/entities/timer_session.dart';
import '../../domain/entities/category.dart';

class TimerSessionModel extends TimerSession {
  const TimerSessionModel({
    super.id,
    required super.createdAt,
    super.updatedAt,
    super.totalDuration,
    super.totalPausedDuration,
    super.isRunning,
    super.isPaused,
    super.category,
    super.label,
  });

  factory TimerSessionModel.fromEntity(TimerSession session) {
    return TimerSessionModel(
      id: session.id,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      totalDuration: session.totalDuration,
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      totalDuration: map['totalDuration'] as int? ?? 0,
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
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'totalDuration': totalDuration,
      'totalPausedDuration': totalPausedDuration,
      'isRunning': isRunning ? 1 : 0,
      'isPaused': isPaused ? 1 : 0,
      'categoryId': category?.id,
      'label': label,
    };
  }

  TimerSessionModel copyWithModel({
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
    return TimerSessionModel(
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
