import '../../domain/entities/session_log.dart';

class SessionLogModel extends SessionLog {
  const SessionLogModel({
    super.id,
    super.sessionId,
    required super.timestamp,
    required super.action,
    super.details,
  });

  factory SessionLogModel.fromEntity(SessionLog log) {
    return SessionLogModel(
      id: log.id,
      sessionId: log.sessionId,
      timestamp: log.timestamp,
      action: log.action,
      details: log.details,
    );
  }

  factory SessionLogModel.fromMap(Map<String, dynamic> map) {
    final actionName = map['action'] as String;
    final action = SessionAction.values.firstWhere(
      (value) => value.name == actionName,
      orElse: () => SessionAction.start,
    );

    return SessionLogModel(
      id: map['id'] as int?,
      sessionId: map['sessionId'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      action: action,
      details: map['details'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'action': action.name,
      'details': details,
    };
  }
}
