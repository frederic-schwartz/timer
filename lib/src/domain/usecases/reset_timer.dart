import '../repositories/timer_repository.dart';

class ResetTimer {
  ResetTimer(this._repository);

  final TimerRepository _repository;

  Future<void> call() => _repository.reset();
}