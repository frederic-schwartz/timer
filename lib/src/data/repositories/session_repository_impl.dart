import '../../domain/entities/timer_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_data_source.dart';
import '../models/timer_session_model.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._localDataSource);

  final SessionLocalDataSource _localDataSource;

  @override
  Future<int> insertSession(TimerSession session) {
    final model = TimerSessionModel.fromEntity(session);
    return _localDataSource.insertSession(model);
  }

  @override
  Future<TimerSession?> getCurrentSession() async {
    final model = await _localDataSource.getCurrentSession();
    return model;
  }

  @override
  Future<void> updateSession(TimerSession session) {
    final model = TimerSessionModel.fromEntity(session);
    return _localDataSource.updateSession(model);
  }

  @override
  Future<List<TimerSession>> getAllSessions() async {
    final models = await _localDataSource.getAllSessions();
    return models;
  }

  @override
  Future<void> deleteSession(int id) => _localDataSource.deleteSession(id);

}
