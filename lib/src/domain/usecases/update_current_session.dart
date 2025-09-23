import '../entities/category.dart';
import '../repositories/timer_repository.dart';

class UpdateCurrentSession {
  UpdateCurrentSession(this._repository);

  final TimerRepository _repository;

  Future<void> call({
    DateTime? startedAt,
    DateTime? endedAt,
    int? totalPauseDuration,
    Category? category,
    String? label,
  }) => _repository.updateCurrentSession(
        startedAt: startedAt,
        endedAt: endedAt,
        totalPauseDuration: totalPauseDuration,
        category: category,
        label: label,
      );
}