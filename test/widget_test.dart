// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:timer/models/session_log.dart';

void main() {
  group('SessionLog Model Tests', () {
    test('SessionLog creation and serialization', () {
      final log = SessionLog(
        id: 1,
        sessionId: 123,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        action: SessionAction.start,
        details: 'Test start action',
      );

      expect(log.id, 1);
      expect(log.sessionId, 123);
      expect(log.action, SessionAction.start);
      expect(log.details, 'Test start action');
    });

    test('SessionLog toMap and fromMap', () {
      final originalLog = SessionLog(
        id: 1,
        sessionId: 123,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        action: SessionAction.pause,
        details: 'Test pause action',
      );

      final map = originalLog.toMap();
      final recreatedLog = SessionLog.fromMap(map);

      expect(recreatedLog.id, originalLog.id);
      expect(recreatedLog.sessionId, originalLog.sessionId);
      expect(recreatedLog.timestamp, originalLog.timestamp);
      expect(recreatedLog.action, originalLog.action);
      expect(recreatedLog.details, originalLog.details);
    });

    test('SessionAction enum values', () {
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
