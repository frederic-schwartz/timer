import '../entities/timer_session.dart';
import '../repositories/session_repository.dart';

class UpdateSessionTimes {
  UpdateSessionTimes(this._repository);

  final SessionRepository _repository;

  Future<TimerSession> call({
    required TimerSession session,
    required DateTime startTime,
    DateTime? endTime,
    Duration? totalPausedDuration,
    bool? isRunning,
    bool? isPaused,
  }) async {
    final updated = session.copyWith(
      startTime: startTime,
      endTime: endTime,
      totalPausedDuration: totalPausedDuration?.inMilliseconds,
      isRunning: isRunning ?? session.isRunning,
      isPaused: isPaused ?? session.isPaused,
    );
    await _repository.updateSession(updated);
    return updated;
  }
}
