import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/timer_state.dart';
import '../models/timer_session_model.dart';
import 'session_local_data_source.dart';

class TimerLocalDataSource {
  TimerLocalDataSource(this._sessionLocalDataSource);

  static const String _pauseStartTimeKey = 'pause_start_time';

  final SessionLocalDataSource _sessionLocalDataSource;

  TimerSessionModel? _currentSession;
  Timer? _timer;
  DateTime? _pauseStartTime; // Quand la pause actuelle a commencé

  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<TimerState> _stateController = StreamController<TimerState>.broadcast();

  Stream<Duration> get durationStream => _durationController.stream;
  Stream<TimerState> get stateStream => _stateController.stream;

  TimerSessionModel? get currentSession => _currentSession;

  TimerState get currentState {
    if (_currentSession == null) return TimerState.stopped;
    if (_currentSession!.isPaused) return TimerState.paused;
    if (_currentSession!.isRunning) return TimerState.running;
    return TimerState.finished;
  }

  Duration get currentDuration {
    if (_currentSession == null) return Duration.zero;

    // Si session terminée, retourner la durée stockée
    if (!_currentSession!.isRunning && !_currentSession!.isPaused) {
      return _currentSession!.totalDuration;
    }

    // Si session en pause, calculer jusqu'au moment de la pause
    if (_currentSession!.isPaused && _pauseStartTime != null) {
      final pauseTime = _pauseStartTime!;
      final durationUntilPause = pauseTime.difference(_currentSession!.startedAt);
      final totalPause = Duration(milliseconds: _currentSession!.totalPauseDuration);
      return durationUntilPause - totalPause;
    }

    // Si session en cours, calculer en temps réel
    if (_currentSession!.isRunning) {
      final now = DateTime.now();
      final totalElapsed = now.difference(_currentSession!.startedAt);
      final totalPause = Duration(milliseconds: _currentSession!.totalPauseDuration);
      return totalElapsed - totalPause;
    }

    return _currentSession!.totalDuration;
  }

  Duration get totalPausedDuration {
    return Duration(milliseconds: _currentSession?.totalPauseDuration ?? 0);
  }

  Duration get currentPauseDuration {
    if (_currentSession == null || !_currentSession!.isPaused || _pauseStartTime == null) {
      return Duration.zero;
    }

    final now = DateTime.now();
    return now.difference(_pauseStartTime!);
  }

  Duration get totalPausedDurationRealTime {
    final basePauseDuration = Duration(milliseconds: _currentSession?.totalPauseDuration ?? 0);
    if (_currentSession != null && _currentSession!.isPaused && _pauseStartTime != null) {
      final currentPause = DateTime.now().difference(_pauseStartTime!);
      return basePauseDuration + currentPause;
    }
    return basePauseDuration;
  }

  Future<void> initialize() async {
    _currentSession = await _sessionLocalDataSource.getCurrentSession();
    await _loadPauseState();

    if (_currentSession != null && (_currentSession!.isRunning || _currentSession!.isPaused)) {
      _startTimer();
      _stateController.add(currentState);
    } else {
      _stateController.add(currentState);
    }

    _durationController.add(currentDuration);
  }

  Future<void> _loadPauseState() async {
    final prefs = await SharedPreferences.getInstance();
    final pauseStartTimeMs = prefs.getInt(_pauseStartTimeKey);

    if (pauseStartTimeMs != null && _currentSession != null && _currentSession!.isPaused) {
      _pauseStartTime = DateTime.fromMillisecondsSinceEpoch(pauseStartTimeMs);
    }
  }

  Future<void> _savePauseState() async {
    final prefs = await SharedPreferences.getInstance();

    if (_pauseStartTime != null) {
      await prefs.setInt(_pauseStartTimeKey, _pauseStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_pauseStartTimeKey);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_currentSession != null && (_currentSession!.isRunning || _currentSession!.isPaused)) {
        // Mettre à jour pour les sessions actives et en pause (pour afficher le temps de pause en cours)
        _durationController.add(currentDuration);
      }
    });
  }

  Future<void> startTimer({Category? category, String? label}) async {
    final now = DateTime.now();

    if (_currentSession != null && _currentSession!.isRunning) return;

    // Si session en pause, la reprendre
    if (_currentSession != null && _currentSession!.isPaused) {
      await _resumeCurrentSession();
      return;
    }

    // Créer nouvelle session
    final session = TimerSessionModel(
      startedAt: now,
      category: category,
      label: label,
    );

    final id = await _sessionLocalDataSource.insertSession(session);
    _currentSession = session.copyWithModel(id: id);

    _startTimer();
    _stateController.add(TimerState.running);
  }

  Future<void> pauseTimer() async {
    if (_currentSession != null && _currentSession!.isRunning) {
      final now = DateTime.now();
      _pauseStartTime = now;

      _currentSession = _currentSession!.copyWithModel(
        isPaused: true,
      );

      await _sessionLocalDataSource.updateSession(_currentSession!);
      await _savePauseState();

      _stateController.add(TimerState.paused);
      // Mettre à jour la durée affichée pour qu'elle se fixe immédiatement
      _durationController.add(currentDuration);
    }
  }

  Future<void> _resumeCurrentSession() async {
    if (_currentSession != null && _currentSession!.isPaused) {
      final now = DateTime.now();

      // Calculer la durée de pause actuelle
      int additionalPauseDuration = 0;
      if (_pauseStartTime != null) {
        additionalPauseDuration = now.difference(_pauseStartTime!).inMilliseconds;
        _pauseStartTime = null;
      }

      _currentSession = _currentSession!.copyWithModel(
        isPaused: false,
        totalPauseDuration: _currentSession!.totalPauseDuration + additionalPauseDuration,
      );

      await _sessionLocalDataSource.updateSession(_currentSession!);
      await _savePauseState();

      _stateController.add(TimerState.running);
    }
  }

  Future<void> stopTimer() async {
    if (_currentSession != null && (_currentSession!.isRunning || _currentSession!.isPaused)) {
      final now = DateTime.now();

      // Si en pause, ajouter la durée de pause actuelle
      int finalPauseDuration = _currentSession!.totalPauseDuration;
      if (_currentSession!.isPaused && _pauseStartTime != null) {
        finalPauseDuration += now.difference(_pauseStartTime!).inMilliseconds;
        _pauseStartTime = null;
      }

      _currentSession = _currentSession!.copyWithModel(
        endedAt: now,
        isPaused: false,
        totalPauseDuration: finalPauseDuration,
      );

      await _sessionLocalDataSource.updateSession(_currentSession!);
      await _savePauseState();

      _stateController.add(TimerState.finished);
      _durationController.add(_currentSession!.totalDuration);

      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> reset() async {
    _timer?.cancel();
    _timer = null;

    _currentSession = null;
    _pauseStartTime = null;

    await _clearPauseState();

    _stateController.add(TimerState.stopped);
    _durationController.add(Duration.zero);
  }

  Future<void> updateCurrentSession({
    DateTime? startedAt,
    DateTime? endedAt,
    int? totalPauseDuration,
    Category? category,
    String? label,
  }) async {
    if (_currentSession != null && _currentSession!.id != null) {
      _currentSession = _currentSession!.copyWithModel(
        startedAt: startedAt,
        endedAt: endedAt,
        totalPauseDuration: totalPauseDuration,
        category: category,
        label: label,
      );

      await _sessionLocalDataSource.updateSession(_currentSession!);
      _durationController.add(_currentSession!.totalDuration);
    }
  }

  Future<void> _clearPauseState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pauseStartTimeKey);
  }

  void dispose() {
    _timer?.cancel();
    _durationController.close();
    _stateController.close();
  }
}