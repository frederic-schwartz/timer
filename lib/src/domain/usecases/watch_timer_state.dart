import '../entities/timer_state.dart';
import '../repositories/timer_repository.dart';

class WatchTimerState {
  WatchTimerState(this._repository);

  final TimerRepository _repository;

  Stream<TimerState> call() => _repository.watchState();
}
