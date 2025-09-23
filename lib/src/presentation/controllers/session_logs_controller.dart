import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/session_log.dart';

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
}
