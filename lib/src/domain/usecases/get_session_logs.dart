import '../entities/session_log.dart';
import '../repositories/session_repository.dart';

class GetSessionLogs {
  GetSessionLogs(this._repository);

  final SessionRepository _repository;

  Future<List<SessionLog>> call(int sessionId) => _repository.getSessionLogs(sessionId);
}
