import '../repositories/timer_repository.dart';

class StartTimer {
  StartTimer(this._repository);

  final TimerRepository _repository;

  Future<void> call() => _repository.startTimer();
}
