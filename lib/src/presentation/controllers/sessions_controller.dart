import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/timer_session.dart';

class SessionsController extends ChangeNotifier {
  SessionsController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  List<TimerSession> _sessions = const [];
  bool _isLoading = true;

  List<TimerSession> get sessions => _sessions;
  bool get isLoading => _isLoading;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allSessions = await _dependencies.getAllSessions();
      _sessions = allSessions.where((session) => !session.isRunning).toList();
    } catch (_) {
      _sessions = const [];
    }

    _isLoading = false;
    notifyListeners();
  }


  Future<void> deleteSession(TimerSession session) async {
    final id = session.id;
    if (id == null) return;
    await _dependencies.deleteSession(id);
    await loadSessions();
  }
}
