import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_session.dart';
import 'database_service.dart';

class TimerService {
  static const String _pauseStartTimeKey = 'pause_start_time';
  static const String _totalPausedDurationKey = 'total_paused_duration';

  TimerSession? _currentSession;
  Timer? _timer;
  DateTime? _pauseStartTime;
  int _totalPausedDuration = 0;
  Duration? _frozenDuration; // Duration when session is in ready state

  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<TimerState> _stateController = StreamController<TimerState>.broadcast();

  Stream<Duration> get durationStream => _durationController.stream;
  Stream<TimerState> get stateStream => _stateController.stream;

  TimerState get currentState {
    if (_currentSession == null) return TimerState.stopped;
    if (_currentSession!.isPaused) return TimerState.paused;
    if (_currentSession!.isRunning) return TimerState.running;
    return TimerState.ready;
  }

  Duration get currentDuration {
    if (_currentSession == null) return Duration.zero;

    // If session is in ready state, return the frozen duration
    if (!_currentSession!.isRunning && _frozenDuration != null) {
      return _frozenDuration!;
    }

    DateTime endTime;
    if (_currentSession!.isPaused && _pauseStartTime != null) {
      // If paused, use the pause start time as the end time
      endTime = _pauseStartTime!;
    } else {
      // If running, use current time
      endTime = DateTime.now();
    }

    final elapsed = endTime.difference(_currentSession!.startTime).inMilliseconds;
    return Duration(milliseconds: elapsed - _totalPausedDuration);
  }

  Duration get totalPausedDuration {
    return Duration(milliseconds: _totalPausedDuration);
  }

  Duration get currentPauseDuration {
    if (_currentSession == null || !_currentSession!.isPaused || _pauseStartTime == null) {
      return Duration.zero;
    }

    final now = DateTime.now();
    return now.difference(_pauseStartTime!);
  }

  Future<void> initialize() async {
    await _loadCurrentSession();
    await _loadPauseState();

    // Start the timer only if we have a running or paused session
    if (_currentSession != null && _currentSession!.isRunning) {
      _startTimer();
    }
  }

  Future<void> _loadCurrentSession() async {
    _currentSession = await DatabaseService.getCurrentSession();
    if (_currentSession != null) {
      _totalPausedDuration = _currentSession!.totalPausedDuration;
    }
  }

  Future<void> _loadPauseState() async {
    final prefs = await SharedPreferences.getInstance();
    final pauseStartTimeMs = prefs.getInt(_pauseStartTimeKey);
    _totalPausedDuration = prefs.getInt(_totalPausedDurationKey) ?? 0;

    if (pauseStartTimeMs != null && _currentSession != null && _currentSession!.isPaused) {
      _pauseStartTime = DateTime.fromMillisecondsSinceEpoch(pauseStartTimeMs);
      // Don't add time since app closure - this time doesn't count as "pause time"
      // The pause time will be calculated properly when resuming
    }
  }

  Future<void> _savePauseState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_pauseStartTime != null) {
      await prefs.setInt(_pauseStartTimeKey, _pauseStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_pauseStartTimeKey);
    }
    await prefs.setInt(_totalPausedDurationKey, _totalPausedDuration);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_currentSession != null && _currentSession!.isRunning) {
        _durationController.add(currentDuration);
      }
    });
  }

  Future<void> startTimer() async {
    if (_currentSession == null) {
      // Start new session
      final session = TimerSession(startTime: DateTime.now());
      final id = await DatabaseService.insertSession(session);
      _currentSession = session.copyWith(id: id);
      _totalPausedDuration = 0;
    } else if (_currentSession!.isPaused) {
      // Resume from pause
      if (_pauseStartTime != null) {
        // Only add the actual pause duration (from pause button press to resume)
        final pauseDuration = DateTime.now().difference(_pauseStartTime!).inMilliseconds;
        _totalPausedDuration += pauseDuration;
        _pauseStartTime = null;
      }

      _currentSession = _currentSession!.copyWith(isPaused: false, isRunning: true);
      await DatabaseService.updateSession(_currentSession!.copyWith(
        totalPausedDuration: _totalPausedDuration,
      ));
    } else if (!_currentSession!.isRunning) {
      // Resume from ready state (resumed session)
      if (_frozenDuration != null) {
        // Adjust start time to account for the frozen duration
        _currentSession = _currentSession!.copyWith(
          isRunning: true,
          startTime: DateTime.now().subtract(_frozenDuration!),
        );
        _frozenDuration = null; // Clear frozen duration
      } else {
        _currentSession = _currentSession!.copyWith(isRunning: true);
      }
      await DatabaseService.updateSession(_currentSession!);
    }

    await _savePauseState();
    _startTimer(); // Start the periodic timer when resuming
    _stateController.add(TimerState.running);
  }

  Future<void> pauseTimer() async {
    if (_currentSession != null && !_currentSession!.isPaused) {
      _pauseStartTime = DateTime.now();
      _currentSession = _currentSession!.copyWith(isPaused: true);

      // Keep the timer running to update pause duration display

      await DatabaseService.updateSession(_currentSession!.copyWith(
        totalPausedDuration: _totalPausedDuration,
      ));
      await _savePauseState();
      _stateController.add(TimerState.paused);
    }
  }

  Future<void> stopTimer() async {
    if (_currentSession != null) {
      // If paused, add final pause duration
      if (_pauseStartTime != null) {
        final pauseDuration = DateTime.now().difference(_pauseStartTime!).inMilliseconds;
        _totalPausedDuration += pauseDuration;
      }

      final endedSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        isRunning: false,
        isPaused: false,
        totalPausedDuration: _totalPausedDuration,
      );

      await DatabaseService.updateSession(endedSession);
      _currentSession = null;
      _pauseStartTime = null;
      _totalPausedDuration = 0;
      _frozenDuration = null; // Clear frozen duration

      await _savePauseState();
      _durationController.add(Duration.zero);
      _stateController.add(TimerState.stopped);
    }
  }

  Future<void> resumeSession(TimerSession session) async {
    // Stop any current session
    await stopTimer();

    // Create a new session that continues from the previous one but starts ready
    final newSession = TimerSession(
      startTime: DateTime.now(),
      totalPausedDuration: 0,
      isRunning: false, // Not running yet, just ready
      isPaused: false,
    );

    final id = await DatabaseService.insertSession(newSession);
    _currentSession = newSession.copyWith(id: id);
    _totalPausedDuration = 0;

    // Store the previous session duration as frozen duration
    final previousDuration = session.currentDuration;
    _frozenDuration = previousDuration;

    // No pause start time - this is a resumed session, not a paused one
    _pauseStartTime = null;

    await DatabaseService.updateSession(_currentSession!);
    await _savePauseState();

    // Stop the timer - session is ready but not running
    _timer?.cancel();
    _durationController.add(previousDuration);
    _stateController.add(TimerState.ready);
  }

  void dispose() {
    _timer?.cancel();
    _durationController.close();
    _stateController.close();
  }
}

enum TimerState { stopped, running, paused, ready }