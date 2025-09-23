import '../entities/session_log.dart';
import '../entities/timer_session.dart';

abstract class SessionRepository {
  Future<int> insertSession(TimerSession session);
  Future<TimerSession?> getCurrentSession();
  Future<void> updateSession(TimerSession session);
  Future<List<TimerSession>> getAllSessions();
  Future<void> deleteSession(int id);

  Future<int> insertSessionLog(SessionLog log);
  Future<List<SessionLog>> getSessionLogs(int sessionId);
  Future<List<SessionLog>> getAllLogs();
  Future<void> deleteSessionLogs(int sessionId);
  Future<void> deleteAllLogs();
}
