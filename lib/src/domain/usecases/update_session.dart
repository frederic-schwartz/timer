import '../entities/timer_session.dart';
import '../repositories/session_repository.dart';

class UpdateSession {
  UpdateSession(this._sessionRepository);

  final SessionRepository _sessionRepository;

  Future<void> call(TimerSession session) {
    return _sessionRepository.updateSession(session);
  }
}