import '../repositories/timer_repository.dart';

class StartNewSession {
  StartNewSession(this._repository);

  final TimerRepository _repository;

  Future<void> call() => _repository.startNewSession();
}
