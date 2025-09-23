import '../entities/timer_session.dart';

abstract class SessionRepository {
  Future<int> insertSession(TimerSession session);
  Future<TimerSession?> getCurrentSession();
  Future<void> updateSession(TimerSession session);
  Future<List<TimerSession>> getAllSessions();
  Future<void> deleteSession(int id);

}
