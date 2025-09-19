import '../repositories/session_repository.dart';

class DeleteSession {
  DeleteSession(this._repository);

  final SessionRepository _repository;

  Future<void> call(int id) => _repository.deleteSession(id);
}
