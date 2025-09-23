import '../repositories/timer_repository.dart';

class PauseTimer {
  PauseTimer(this._repository);

  final TimerRepository _repository;

  Future<void> call() => _repository.pauseTimer();
}