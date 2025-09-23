import '../entities/category.dart';
import '../repositories/timer_repository.dart';

class StartTimer {
  StartTimer(this._repository);

  final TimerRepository _repository;

  Future<void> call({Category? category, String? label}) =>
      _repository.startTimer(category: category, label: label);
}
