import 'dart:async';
import 'dart:core';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/timer_state.dart';
import '../models/timer_session_model.dart';
import 'session_local_data_source.dart';

class TimerLocalDataSource {
  TimerLocalDataSource(this._sessionLocalDataSource);

  static const String _pauseStartTimeKey = 'pause_start_time';
  static const String _sessionStartTimeKey = 'session_start_time';

  final SessionLocalDataSource _sessionLocalDataSource;

  TimerSessionModel? _currentSession;
  Timer? _timer;
  DateTime? _pauseStartTime;
  DateTime? _sessionStartTime; // Quand la session actuelle a commencé

  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<TimerState> _stateController = StreamController<TimerState>.broadcast();

  Stream<Duration> get durationStream => _durationController.stream;
  Stream<TimerState> get stateStream => _stateController.stream;

  TimerSessionModel? get currentSession => _currentSession;

  TimerState get currentState {
    if (_currentSession == null) return TimerState.stopped;
    if (_currentSession!.isPaused) return TimerState.paused;
    if (_currentSession!.isRunning) return TimerState.running;
    // Si on a une session mais pas en cours, c'est soit ready soit finished
    if (_sessionStartTime == null) return TimerState.ready;
    return TimerState.finished;
  }

  Duration get currentDuration {
    if (_currentSession == null) return Duration.zero;

    // Si session pas en cours, retourner la durée stockée
    if (!_currentSession!.isRunning) {
      return Duration(milliseconds: _currentSession!.totalDuration);
    }

    // Session en cours - calculer durée actuelle
    if (_sessionStartTime == null) return Duration.zero;

    DateTime endTime;
    if (_currentSession!.isPaused && _pauseStartTime != null) {
      endTime = _pauseStartTime!;
    } else {
      endTime = DateTime.now();
    }

    final elapsedThisSession = endTime.difference(_sessionStartTime!).inMilliseconds;
    final currentPauseDuration = _currentSession!.isPaused && _pauseStartTime != null
        ? endTime.difference(_pauseStartTime!).inMilliseconds
        : 0;

    final totalDuration = _currentSession!.totalDuration + elapsedThisSession - currentPauseDuration;
    return Duration(milliseconds: totalDuration);
  }

  Duration get totalPausedDuration => Duration(milliseconds: _currentSession?.totalPausedDuration ?? 0);

  Duration get currentPauseDuration {
    if (_currentSession == null || !_currentSession!.isPaused || _pauseStartTime == null) {
      return Duration.zero;
    }

    final now = DateTime.now();
    return now.difference(_pauseStartTime!);
  }

  Duration get totalPausedDurationRealTime {
    final basePauseDuration = Duration(milliseconds: _currentSession?.totalPausedDuration ?? 0);
    if (_currentSession != null && _currentSession!.isPaused && _pauseStartTime != null) {
      final currentPause = DateTime.now().difference(_pauseStartTime!);
      return basePauseDuration + currentPause;
    }
    return basePauseDuration;
  }

  Future<void> initialize() async {
    await _loadCurrentSession();
    await _loadState();

    if (_currentSession != null && _currentSession!.isRunning) {
      _startTimer();
    }
  }

  Future<void> _loadCurrentSession() async {
    _currentSession = await _sessionLocalDataSource.getCurrentSession();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final pauseStartTimeMs = prefs.getInt(_pauseStartTimeKey);
    final sessionStartTimeMs = prefs.getInt(_sessionStartTimeKey);

    if (pauseStartTimeMs != null && _currentSession != null && _currentSession!.isPaused) {
      _pauseStartTime = DateTime.fromMillisecondsSinceEpoch(pauseStartTimeMs);
    }

    if (sessionStartTimeMs != null && _currentSession != null && _currentSession!.isRunning) {
      _sessionStartTime = DateTime.fromMillisecondsSinceEpoch(sessionStartTimeMs);
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();

    if (_pauseStartTime != null) {
      await prefs.setInt(_pauseStartTimeKey, _pauseStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_pauseStartTimeKey);
    }

    if (_sessionStartTime != null) {
      await prefs.setInt(_sessionStartTimeKey, _sessionStartTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_sessionStartTimeKey);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_currentSession != null && (_currentSession!.isRunning || _currentSession!.isPaused)) {
        _durationController.add(currentDuration);
      }
    });
  }

  Future<void> startTimer({Category? category, String? label}) async {
    final now = DateTime.now();

    // Si pas de session, en créer une nouvelle
    if (_currentSession == null) {
      final session = TimerSessionModel(
        createdAt: now,
        updatedAt: now,
        category: category,
        label: label,
      );
      final id = await _sessionLocalDataSource.insertSession(session);
      _currentSession = session.copyWithModel(id: id);
      _sessionStartTime = now;

      _durationController.add(Duration.zero);
    }
    // Si session en pause, la reprendre
    else if (_currentSession!.isPaused) {
      // Calculer la durée de pause actuelle
      int pauseDuration = 0;
      if (_pauseStartTime != null) {
        pauseDuration = now.difference(_pauseStartTime!).inMilliseconds;
        _pauseStartTime = null;
      }

      _currentSession = _currentSession!.copyWithModel(
        isPaused: false,
        isRunning: true,
        updatedAt: now,
        totalPausedDuration: _currentSession!.totalPausedDuration + pauseDuration,
      );
      await _sessionLocalDataSource.updateSession(_currentSession!);
    }
    // Si session prête (not running), la démarrer/reprendre
    else if (!_currentSession!.isRunning) {
      _currentSession = _currentSession!.copyWithModel(
        isRunning: true,
        updatedAt: now,
        category: category ?? _currentSession!.category,
        label: label ?? _currentSession!.label,
      );
      _sessionStartTime = now;
      await _sessionLocalDataSource.updateSession(_currentSession!);
    }

    await _saveState();
    _startTimer();
    _stateController.add(TimerState.running);
  }

  Future<void> pauseTimer() async {
    if (_currentSession != null && !_currentSession!.isPaused) {
      final now = DateTime.now();
      _pauseStartTime = now;

      _currentSession = _currentSession!.copyWithModel(
        isPaused: true,
        updatedAt: now,
      );

      await _sessionLocalDataSource.updateSession(_currentSession!);
      await _saveState();

      _stateController.add(TimerState.paused);
    }
  }

  Future<void> stopTimer() async {
    if (_currentSession != null) {
      final now = DateTime.now();

      // Calculer la durée finale
      int finalTotalDuration = _currentSession!.totalDuration;
      int finalPausedDuration = _currentSession!.totalPausedDuration;

      // Si on était en cours d'exécution, ajouter le temps écoulé
      if (_sessionStartTime != null) {
        final elapsedThisSession = now.difference(_sessionStartTime!).inMilliseconds;
        finalTotalDuration += elapsedThisSession;
      }

      // Si on était en pause, ajouter la durée de pause actuelle
      if (_currentSession!.isPaused && _pauseStartTime != null) {
        final pauseDuration = now.difference(_pauseStartTime!).inMilliseconds;
        finalPausedDuration += pauseDuration;
        _pauseStartTime = null;
      }

      _currentSession = _currentSession!.copyWithModel(
        isRunning: false,
        isPaused: false,
        updatedAt: now, // Mettre à jour pour apparaître en haut de liste
        totalDuration: finalTotalDuration,
        totalPausedDuration: finalPausedDuration,
      );

      await _sessionLocalDataSource.updateSession(_currentSession!);

      _sessionStartTime = null;
      _stateController.add(TimerState.finished);
      _durationController.add(_currentSession!.currentDuration);

      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> resumeSession(TimerSessionModel session) async {
    if (session.id == null) return;

    // Préparer la session pour reprise
    _currentSession = session.copyWithModel(
      isRunning: false,
      isPaused: false,
    );

    _sessionStartTime = null; // Sera défini quand on démarrera
    _pauseStartTime = null;

    _stateController.add(TimerState.ready);
    _durationController.add(session.currentDuration);
  }

  Future<void> reset() async {
    _timer?.cancel();
    _timer = null;

    _currentSession = null;
    _pauseStartTime = null;
    _sessionStartTime = null;

    await _clearState();

    _stateController.add(TimerState.stopped);
    _durationController.add(Duration.zero);
  }

  Future<void> updateCurrentSessionCategoryLabel(Category? category, String? label) async {
    if (_currentSession != null && _currentSession!.id != null) {
      _currentSession = _currentSession!.copyWithModel(
        category: category,
        label: label,
        updatedAt: DateTime.now(),
      );

      await _sessionLocalDataSource.updateSession(_currentSession!);
    }
  }

  Future<void> _clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pauseStartTimeKey);
    await prefs.remove(_sessionStartTimeKey);
  }

  void dispose() {
    _timer?.cancel();
    _durationController.close();
    _stateController.close();
  }
}
