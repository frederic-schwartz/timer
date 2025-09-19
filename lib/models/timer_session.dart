class TimerSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalPausedDuration; // in milliseconds
  final bool isRunning;
  final bool isPaused;

  TimerSession({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'totalPausedDuration': totalPausedDuration,
      'isRunning': isRunning ? 1 : 0,
      'isPaused': isPaused ? 1 : 0,
    };
  }

  static TimerSession fromMap(Map<String, dynamic> map) {
    return TimerSession(
      id: map['id'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      totalPausedDuration: map['totalPausedDuration'] ?? 0,
      isRunning: map['isRunning'] == 1,
      isPaused: map['isPaused'] == 1,
    );
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