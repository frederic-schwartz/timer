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
  static const String _totalPausedDurationKey = 'total_paused_duration';

  final SessionLocalDataSource _sessionLocalDataSource;

  TimerSessionModel? _currentSession;
  Timer? _timer;
  DateTime? _pauseStartTime;
  int _totalPausedDuration = 0;
  Duration? _frozenDuration;
  bool _isResumedSession = false;

  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<TimerState> _stateController = StreamController<TimerState>.broadcast();

  Stream<Duration> get durationStream => _durationController.stream;
  Stream<TimerState> get stateStream => _stateController.stream;

  TimerSessionModel? get currentSession => _currentSession;

  TimerState get currentState {
    if (_currentSession == null) return TimerState.stopped;
    if (_currentSession!.isPaused) return TimerState.paused;
    if (_currentSession!.isRunning) return TimerState.running;
    // Si c'est une session reprise, c'est ready
    if (_isResumedSession) return TimerState.ready;
    // Si la session a un endTime, c'est qu'elle a été stoppée (finished)
    if (_currentSession!.endTime != null) return TimerState.finished;
    // Sinon c'est une session prête à être reprise ou continuée (ready)
    return TimerState.ready;
  }

  Duration get currentDuration {
    if (_currentSession == null) return Duration.zero;

    if (!_currentSession!.isRunning && _frozenDuration != null) {
      return _frozenDuration!;
    }

    DateTime endTime;
    if (_currentSession!.isPaused && _pauseStartTime != null) {
      endTime = _pauseStartTime!;
    } else {
      endTime = DateTime.now();
    }

    final elapsed = endTime.difference(_currentSession!.startTime).inMilliseconds;
    return Duration(milliseconds: elapsed - _totalPausedDuration);
  }

  Duration get totalPausedDuration => Duration(milliseconds: _totalPausedDuration);

  Duration get currentPauseDuration {
    if (_currentSession == null || !_currentSession!.isPaused || _pauseStartTime == null) {
      return Duration.zero;
    }

    final now = DateTime.now();
    return now.difference(_pauseStartTime!);
  }

  Duration get totalPausedDurationRealTime {
    final basePauseDuration = Duration(milliseconds: _totalPausedDuration);
    if (_currentSession != null && _currentSession!.isPaused && _pauseStartTime != null) {
      final currentPause = DateTime.now().difference(_pauseStartTime!);
      return basePauseDuration + currentPause;
    }
    return basePauseDuration;
  }

  Future<void> initialize() async {
    await _loadCurrentSession();
    await _loadPauseState();

    if (_currentSession != null && _currentSession!.isRunning) {
      _startTimer();
    }
  }

  Future<void> _loadCurrentSession() async {
    _currentSession = await _sessionLocalDataSource.getCurrentSession();
    if (_currentSession != null) {
      _totalPausedDuration = _currentSession!.totalPausedDuration;
    }
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
    await prefs.setInt(_totalPausedDurationKey, _totalPausedDuration);
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
    // Si pas de session ou session terminée ou session reprise, traiter différemment
    if (_currentSession == null || (_currentSession != null && _currentSession!.endTime != null && !_isResumedSession)) {
      // Créer une nouvelle session
      final session = TimerSessionModel(
        startTime: DateTime.now(),
        category: category,
        label: label,
      );
      final id = await _sessionLocalDataSource.insertSession(session);
      _currentSession = session.copyWithModel(id: id);
      _totalPausedDuration = 0;
      _frozenDuration = null;
      _isResumedSession = false;

      _durationController.add(Duration.zero);
    } else if (_currentSession!.isPaused) {
      if (_pauseStartTime != null) {
        final pauseDuration = DateTime.now().difference(_pauseStartTime!).inMilliseconds;
        _totalPausedDuration += pauseDuration;
        _pauseStartTime = null;
      }

      _currentSession = _currentSession!.copyWithModel(isPaused: false, isRunning: true);
      await _sessionLocalDataSource.updateSession(
        _currentSession!.copyWithModel(totalPausedDuration: _totalPausedDuration),
      );

    } else if (!_currentSession!.isRunning) {
      if (_frozenDuration != null) {
        final totalElapsedTime = _frozenDuration! + Duration(milliseconds: _totalPausedDuration);

        _currentSession = _currentSession!.copyWithModel(
          isRunning: true,
          startTime: DateTime.now().subtract(totalElapsedTime),
          // Garder la catégorie et libellé actuels (possiblement modifiés)
          category: category ?? _currentSession!.category,
          label: label ?? _currentSession!.label,
        );
        _frozenDuration = null;
        _isResumedSession = false; // Plus une session reprise une fois démarrée
      } else {
        _currentSession = _currentSession!.copyWithModel(
          isRunning: true,
          category: category ?? _currentSession!.category,
          label: label ?? _currentSession!.label,
        );
        _isResumedSession = false;
      }
      await _sessionLocalDataSource.updateSession(_currentSession!);
    }

    await _savePauseState();
    _startTimer();
    _stateController.add(TimerState.running);
  }

  Future<void> pauseTimer() async {
    if (_currentSession != null && !_currentSession!.isPaused) {
      _pauseStartTime = DateTime.now();
      _currentSession = _currentSession!.copyWithModel(isPaused: true);

      await _sessionLocalDataSource.updateSession(
        _currentSession!.copyWithModel(totalPausedDuration: _totalPausedDuration),
      );
      await _savePauseState();


      _stateController.add(TimerState.paused);
    }
  }

  Future<void> stopTimer() async {
    if (_currentSession != null) {
      DateTime endTime;
      DateTime? newStartTime;

      if (!_currentSession!.isRunning && _frozenDuration != null) {
        // Session was resumed - update startTime to make it appear at top of list
        endTime = DateTime.now();
        newStartTime = endTime.subtract(_frozenDuration!);
      } else {
        endTime = DateTime.now();
        if (_currentSession!.isPaused && _pauseStartTime != null) {
          final pauseDuration = DateTime.now().difference(_pauseStartTime!).inMilliseconds;
          _totalPausedDuration += pauseDuration;
          _pauseStartTime = null;
        }
      }

      final updatedSession = _currentSession!.copyWithModel(
        isRunning: false,
        isPaused: false,
        startTime: newStartTime ?? _currentSession!.startTime,
        endTime: endTime,
        totalPausedDuration: _totalPausedDuration,
      );

      await _sessionLocalDataSource.updateSession(updatedSession);

      // Garder la session en mémoire pour afficher la durée finale
      _currentSession = updatedSession;
      _frozenDuration = updatedSession.currentDuration;
      _isResumedSession = false; // Session stoppée, pas reprise

      _stateController.add(TimerState.finished);
      _durationController.add(updatedSession.currentDuration);

      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> resumeSession(TimerSessionModel session) async {
    if (session.id == null) return;

    // Garder la session avec endTime mais marquer comme reprise
    _currentSession = session.copyWithModel(
      isRunning: false,
      isPaused: false,
    );
    _isResumedSession = true; // Marquer comme session reprise

    if (session.endTime != null) {
      final totalDuration = session.endTime!.difference(session.startTime);
      _frozenDuration = Duration(milliseconds: totalDuration.inMilliseconds - session.totalPausedDuration);
    } else {
      _frozenDuration = session.currentDuration;
    }

    _totalPausedDuration = session.totalPausedDuration;

    // Ne pas modifier endTime dans la base de données pour l'instant
    // await _sessionLocalDataSource.updateSession(_currentSession!);

    _stateController.add(TimerState.ready);
    _durationController.add(_frozenDuration ?? Duration.zero);
  }

  Future<void> reset() async {
    _timer?.cancel();
    _timer = null;

    _currentSession = null;
    _totalPausedDuration = 0;
    _frozenDuration = null;
    _pauseStartTime = null;
    _isResumedSession = false;

    await _clearPauseState();

    _stateController.add(TimerState.stopped);
    _durationController.add(Duration.zero);
  }

  Future<void> updateCurrentSessionCategoryLabel(Category? category, String? label) async {
    if (_currentSession != null && _currentSession!.id != null) {
      // Mettre à jour la session en mémoire
      _currentSession = _currentSession!.copyWithModel(
        category: category,
        label: label,
      );

      // Pour une session reprise, il faut remettre endTime pour la sauvegarder correctement
      TimerSessionModel sessionToSave = _currentSession!;
      if (_isResumedSession && _frozenDuration != null) {
        // Recalculer endTime basé sur la durée figée
        final endTime = _currentSession!.startTime.add(_frozenDuration! + Duration(milliseconds: _currentSession!.totalPausedDuration));
        sessionToSave = _currentSession!.copyWithModel(endTime: endTime);
      }

      await _sessionLocalDataSource.updateSession(sessionToSave);
    }
  }


  Future<void> _clearPauseState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pauseStartTimeKey);
    await prefs.remove(_totalPausedDurationKey);
  }

  void dispose() {
    _timer?.cancel();
    _durationController.close();
    _stateController.close();
  }
}
