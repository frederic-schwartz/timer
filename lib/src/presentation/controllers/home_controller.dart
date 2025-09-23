import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/timer_session.dart';
import '../../domain/entities/timer_snapshot.dart';
import '../../domain/entities/timer_state.dart';

class HomeController extends ChangeNotifier {
  HomeController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  bool _isInitialized = false;
  bool _isLoading = true;
  Duration _currentDuration = Duration.zero;
  Duration _totalPauseRealTime = Duration.zero;
  Duration _totalPause = Duration.zero;
  Duration _currentPauseDuration = Duration.zero;
  TimerState _currentState = TimerState.stopped;
  List<TimerSession> _recentSessions = const [];

  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<TimerState>? _stateSubscription;

  bool get isLoading => _isLoading;
  Duration get currentDuration => _currentDuration;
  Duration get totalPauseRealTime => _totalPauseRealTime;
  Duration get totalPause => _totalPause;
  Duration get currentPauseDuration => _currentPauseDuration;
  TimerState get currentState => _currentState;
  List<TimerSession> get recentSessions => _recentSessions;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _dependencies.initializeTimer();
    _durationSubscription = _dependencies.watchTimerDuration().listen((_) {
      _updateSnapshot(notify: true);
    });
    _stateSubscription = _dependencies.watchTimerState().listen((state) async {
      _currentState = state;
      _updateSnapshot(notify: true);
      if (state == TimerState.stopped) {
        await loadRecentSessions();
      }
    });

    _updateSnapshot(notify: false);
    await loadRecentSessions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecentSessions() async {
    try {
      final sessions = await _dependencies.getAllSessions();
      final count = await _dependencies.getRecentSessionsCount();
      _recentSessions = sessions
          .where((session) => !session.isRunning)
          .take(count)
          .toList();
    } catch (_) {
      _recentSessions = const [];
    }
    notifyListeners();
  }

  Future<void> startTimer() async {
    await _dependencies.startTimer();
    _updateSnapshot();
  }

  Future<void> pauseTimer() async {
    await _dependencies.pauseTimer();
    _updateSnapshot();
  }

  Future<void> stopTimer() async {
    await _dependencies.stopTimer();
    _updateSnapshot();
  }

  Future<void> resumeSession(TimerSession session) async {
    await _dependencies.resumeSession(session);
    _updateSnapshot();
  }

  Future<void> resetTimer() async {
    await _dependencies.resetTimer();
    _updateSnapshot();
  }

  void _updateSnapshot({bool notify = false}) {
    final TimerSnapshot snapshot = _dependencies.getTimerSnapshot();
    _currentDuration = snapshot.currentDuration;
    _currentState = snapshot.state;
    _totalPauseRealTime = snapshot.totalPausedDurationRealTime;
    _totalPause = snapshot.totalPausedDuration;
    _currentPauseDuration = snapshot.currentPauseDuration;
    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}
