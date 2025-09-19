import '../entities/session_log.dart';
import '../repositories/session_repository.dart';

class UpdateSessionLog {
  UpdateSessionLog(this._repository);

  final SessionRepository _repository;

  Future<void> call(SessionLog log) {
    return _repository.updateSessionLog(log);
  }
}
