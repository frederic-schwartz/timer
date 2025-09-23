import '../../domain/entities/timer_session.dart';
import '../../domain/entities/category.dart';

class TimerSessionModel extends TimerSession {
  const TimerSessionModel({
    super.id,
    required super.startedAt,
    super.endedAt,
    super.totalPauseDuration,
    super.isPaused,
    super.category,
    super.label,
  });

  factory TimerSessionModel.fromEntity(TimerSession session) {
    return TimerSessionModel(
      id: session.id,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      totalPauseDuration: session.totalPauseDuration,
      isPaused: session.isPaused,
      category: session.category,
      label: session.label,
    );
  }

  factory TimerSessionModel.fromMap(Map<String, dynamic> map, {Category? category}) {
    return TimerSessionModel(
      id: map['id'] as int?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int),
      endedAt: map['endedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endedAt'] as int)
          : null,
      totalPauseDuration: map['totalPauseDuration'] as int? ?? 0,
      isPaused: (map['isPaused'] as int? ?? 0) == 1,
      category: category,
      label: map['label'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
      'totalPauseDuration': totalPauseDuration,
      'isPaused': isPaused ? 1 : 0,
      'categoryId': category?.id,
      'label': label,
    };
  }

  TimerSessionModel copyWithModel({
    int? id,
    DateTime? startedAt,
    DateTime? endedAt,
    int? totalPauseDuration,
    bool? isPaused,
    Category? category,
    String? label,
  }) {
    return TimerSessionModel(
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
