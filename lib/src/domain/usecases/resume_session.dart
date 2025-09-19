import '../entities/timer_session.dart';
import '../repositories/timer_repository.dart';

class ResumeSession {
  ResumeSession(this._repository);

  final TimerRepository _repository;

  Future<void> call(TimerSession session) => _repository.resumeSession(session);
}
