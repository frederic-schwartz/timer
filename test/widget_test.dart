import 'package:flutter_test/flutter_test.dart';
import 'package:tockee/src/domain/entities/session_log.dart';

void main() {
  group('SessionLog entity', () {
    test('stores provided values', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      const details = 'Test start action';

      final log = SessionLog(
        id: 1,
        sessionId: 123,
        timestamp: timestamp,
        action: SessionAction.start,
        details: details,
      );

      expect(log.id, 1);
      expect(log.sessionId, 123);
      expect(log.timestamp, timestamp);
      expect(log.action, SessionAction.start);
      expect(log.details, details);
    });

    test('copyWith overrides selected values', () {
      final log = SessionLog(
        id: 1,
        sessionId: 123,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        action: SessionAction.start,
        details: 'Initial',
      );

      final updated = log.copyWith(
        action: SessionAction.pause,
        details: 'Pause action',
      );

      expect(updated.id, log.id);
      expect(updated.sessionId, log.sessionId);
      expect(updated.timestamp, log.timestamp);
      expect(updated.action, SessionAction.pause);
      expect(updated.details, 'Pause action');
    });

    test('SessionAction exposes labels', () {
      expect(SessionAction.start.name, 'start');
      expect(SessionAction.start.displayName, 'Démarrage');
      expect(SessionAction.pause.name, 'pause');
      expect(SessionAction.pause.displayName, 'Pause');
      expect(SessionAction.resume.name, 'resume');
      expect(SessionAction.resume.displayName, 'Reprise');
      expect(SessionAction.stop.name, 'stop');
      expect(SessionAction.stop.displayName, 'Arrêt');
      expect(SessionAction.resumeSession.name, 'resume_session');
      expect(SessionAction.resumeSession.displayName, 'Reprise de session');
    });
  });
}
