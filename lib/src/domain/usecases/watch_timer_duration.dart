import '../repositories/timer_repository.dart';

class WatchTimerDuration {
  WatchTimerDuration(this._repository);

  final TimerRepository _repository;

  Stream<Duration> call() => _repository.watchDuration();
}
