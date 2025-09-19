import '../repositories/session_repository.dart';

class DeleteAllLogs {
  DeleteAllLogs(this._repository);

  final SessionRepository _repository;

  Future<void> call() => _repository.deleteAllLogs();
}
