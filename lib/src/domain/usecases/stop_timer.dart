import '../repositories/timer_repository.dart';

class StopTimer {
  StopTimer(this._repository);

  final TimerRepository _repository;

  Future<void> call() => _repository.stopTimer();
}
