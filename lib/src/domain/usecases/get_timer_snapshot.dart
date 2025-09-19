import '../entities/timer_snapshot.dart';
import '../repositories/timer_repository.dart';

class GetTimerSnapshot {
  GetTimerSnapshot(this._repository);

  final TimerRepository _repository;

  TimerSnapshot call() => _repository.snapshot();
}
