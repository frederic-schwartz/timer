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

  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<TimerState> _stateController = StreamController<TimerState>.broadcast();

  Stream<Duration> get durationStream => _durationController.stream;
  Stream<TimerState> get stateStream => _stateController.stream;

  TimerState get currentState {
    if (_currentSession == null) return TimerState.stopped;
    if (_currentSession!.isPaused) return TimerState.paused;
    return TimerState.running;
  }

  Duration get currentDuration {
    if (_currentSession == null) return Duration.zero;

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

  Future<void> initialize() async {
    await _loadCurrentSession();
    await _loadPauseState();

    // Only start the timer if we have an active (non-paused) session
    if (_currentSession != null && !_currentSession!.isPaused) {
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
      if (_currentSession != null && !_currentSession!.isPaused) {
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

      _currentSession = _currentSession!.copyWith(isPaused: false);
      await DatabaseService.updateSession(_currentSession!.copyWith(
        totalPausedDuration: _totalPausedDuration,
      ));
    }

    await _savePauseState();
    _startTimer(); // Start the periodic timer when resuming
    _stateController.add(TimerState.running);
  }

  Future<void> pauseTimer() async {
    if (_currentSession != null && !_currentSession!.isPaused) {
      _pauseStartTime = DateTime.now();
      _currentSession = _currentSession!.copyWith(isPaused: true);

      _timer?.cancel(); // Stop the periodic timer when pausing

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

      await _savePauseState();
      _durationController.add(Duration.zero);
      _stateController.add(TimerState.stopped);
    }
  }

  void dispose() {
    _timer?.cancel();
    _durationController.close();
    _stateController.close();
  }
}

enum TimerState { stopped, running, paused }