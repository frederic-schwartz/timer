import '../repositories/session_repository.dart';

class DeleteSessionLogs {
  DeleteSessionLogs(this._repository);

  final SessionRepository _repository;

  Future<void> call(int sessionId) => _repository.deleteSessionLogs(sessionId);
}
