import '../entities/session_log.dart';
import '../repositories/session_repository.dart';

class GetAllLogs {
  GetAllLogs(this._repository);

  final SessionRepository _repository;

  Future<List<SessionLog>> call() => _repository.getAllLogs();
}
