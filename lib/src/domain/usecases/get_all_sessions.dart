import '../entities/timer_session.dart';
import '../repositories/session_repository.dart';

class GetAllSessions {
  GetAllSessions(this._repository);

  final SessionRepository _repository;

  Future<List<TimerSession>> call() => _repository.getAllSessions();
}
