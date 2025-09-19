import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/session_log.dart';
import '../../domain/entities/timer_session.dart';

class SessionLogsController extends ChangeNotifier {
  SessionLogsController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  List<SessionLog> _logs = const [];
  bool _isLoading = true;

  List<SessionLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> loadLogs(int sessionId) async {
    _isLoading = true;
    notifyListeners();

    _logs = await _dependencies.getSessionLogs(sessionId);

    _isLoading = false;
    notifyListeners();
  }

  Future<TimerSession> updateSessionTimes({
    required TimerSession session,
    required DateTime startTime,
    DateTime? endTime,
    Duration? totalPausedDuration,
    bool? isRunning,
    bool? isPaused,
  }) {
    return _dependencies.updateSessionTimes(
      session: session,
      startTime: startTime,
      endTime: endTime,
      totalPausedDuration: totalPausedDuration,
      isRunning: isRunning,
      isPaused: isPaused,
    );
  }

  Future<void> updateLog(SessionLog log) {
    return _dependencies.updateSessionLog(log);
  }

  Future<void> refreshTimerService() {
    return _dependencies.initializeTimer();
  }
}
