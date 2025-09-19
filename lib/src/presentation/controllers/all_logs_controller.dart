import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/session_log.dart';
import '../../domain/entities/timer_session.dart';

class AllLogsController extends ChangeNotifier {
  AllLogsController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  List<SessionLog> _logs = const [];
  List<TimerSession> _sessions = const [];
  bool _isLoading = true;
  String _filter = 'all';

  List<SessionLog> get allLogs => _logs;
  List<TimerSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String get filter => _filter;

  List<SessionLog> get filteredLogs {
    if (_filter == 'all') return _logs;
    return _logs.where((log) => log.action.name == _filter).toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _logs = await _dependencies.getAllLogs();
    _sessions = await _dependencies.getAllSessions();

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  TimerSession? sessionForLog(SessionLog log) {
    for (final session in _sessions) {
      if (session.id == log.sessionId) {
        return session;
      }
    }
    return null;
  }

  Future<void> clearAllLogs() async {
    await _dependencies.deleteAllLogs();
    await loadData();
  }
}
