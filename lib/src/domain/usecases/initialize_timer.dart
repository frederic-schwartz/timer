import '../repositories/timer_repository.dart';

class InitializeTimer {
  InitializeTimer(this._repository);

  final TimerRepository _repository;

  Future<void> call() => _repository.initialize();
}
