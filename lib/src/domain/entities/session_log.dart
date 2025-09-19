class SessionLog {
  final int? id;
  final int? sessionId;
  final DateTime timestamp;
  final SessionAction action;
  final String? details;
  final double? latitude;
  final double? longitude;

  const SessionLog({
    this.id,
    this.sessionId,
    required this.timestamp,
    required this.action,
    this.details,
    this.latitude,
    this.longitude,
  });

  SessionLog copyWith({
    int? id,
    int? sessionId,
    DateTime? timestamp,
    SessionAction? action,
    String? details,
    double? latitude,
    double? longitude,
  }) {
    return SessionLog(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      details: details ?? this.details,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  String toString() {
    return 'SessionLog(id: $id, sessionId: $sessionId, timestamp: $timestamp, action: ${action.displayName}, details: $details, latitude: $latitude, longitude: $longitude)';
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
