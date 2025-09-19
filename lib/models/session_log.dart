class SessionLog {
  final int? id;
  final int? sessionId; // Reference to the timer session
  final DateTime timestamp;
  final SessionAction action;
  final String? details; // Optional additional information

  SessionLog({
    this.id,
    this.sessionId,
    required this.timestamp,
    required this.action,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'action': action.name,
      'details': details,
    };
  }

  static SessionLog fromMap(Map<String, dynamic> map) {
    return SessionLog(
      id: map['id'],
      sessionId: map['sessionId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      action: SessionAction.values.firstWhere((e) => e.name == map['action']),
      details: map['details'],
    );
  }

  SessionLog copyWith({
    int? id,
    int? sessionId,
    DateTime? timestamp,
    SessionAction? action,
    String? details,
  }) {
    return SessionLog(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      details: details ?? this.details,
    );
  }

  @override
  String toString() {
    return 'SessionLog(id: $id, sessionId: $sessionId, timestamp: $timestamp, action: ${action.displayName}, details: $details)';
  }
}

enum SessionAction {
  start('start', 'Démarrage'),
  pause('pause', 'Pause'),
  resume('resume', 'Reprise'),
  stop('stop', 'Arrêt'),
  resumeSession('resume_session', 'Reprise de session');

  const SessionAction(this.name, this.displayName);

  final String name;
  final String displayName;
}