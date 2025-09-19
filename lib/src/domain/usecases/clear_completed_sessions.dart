import '../repositories/session_repository.dart';

class ClearCompletedSessions {
  ClearCompletedSessions(this._repository);

  final SessionRepository _repository;

  Future<void> call() async {
    final sessions = await _repository.getAllSessions();
    for (final session in sessions) {
      if (!session.isRunning && session.id != null) {
        await _repository.deleteSession(session.id!);
      }
    }
  }
}
