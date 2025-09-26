import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/category.dart' as entities;
import '../../domain/entities/timer_session.dart';
import '../../domain/entities/timer_snapshot.dart';
import '../../domain/entities/timer_state.dart';

class HomeController extends ChangeNotifier {
  HomeController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  bool _isInitialized = false;
  bool _isLoading = true;
  bool _wakeLockEnabled = false;
  Duration _currentDuration = Duration.zero;
  Duration _totalPauseRealTime = Duration.zero;
  Duration _totalPause = Duration.zero;
  Duration _currentPauseDuration = Duration.zero;
  TimerState _currentState = TimerState.stopped;
  List<TimerSession> _recentSessions = const [];
  List<entities.Category> _categories = const [];
  entities.Category? _selectedCategory;
  String? _selectedLabel;

  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<TimerState>? _stateSubscription;

  bool get isLoading => _isLoading;
  Duration get currentDuration => _currentDuration;
  Duration get totalPauseRealTime => _totalPauseRealTime;
  Duration get totalPause => _totalPause;
  Duration get currentPauseDuration => _currentPauseDuration;
  TimerState get currentState => _currentState;
  List<TimerSession> get recentSessions => _recentSessions;
  List<entities.Category> get categories => _categories;
  entities.Category? get selectedCategory => _selectedCategory;
  String? get selectedLabel => _selectedLabel;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _dependencies.initializeTimer();

    // Tentative de restauration depuis iCloud après l'initialisation de la base
    final restored = await _dependencies.restoreAppData.call();
    if (restored && kDebugMode) {
      print('🔒 Données restaurées depuis iCloud');
    }
    _wakeLockEnabled = await _dependencies.getWakeLockEnabled();
    if (kDebugMode) {
      print('🔒 Wake lock setting loaded: $_wakeLockEnabled');
    }

    _durationSubscription = _dependencies.watchTimerDuration().listen((_) {
      _updateSnapshot(notify: true);
    });
    _stateSubscription = _dependencies.watchTimerState().listen((state) async {
      _currentState = state;
      _updateSnapshot(notify: true);
      await _manageWakeLock(state);
      if (state == TimerState.finished) {
        await loadRecentSessions();
      }
    });

    _updateSnapshot(notify: false);
    await loadRecentSessions();
    await loadCategories();

    // Récupérer catégorie et libellé de la session courante si elle existe
    await _loadCurrentSessionData();

    // Gérer le wake lock initial
    await _manageWakeLock(_currentState);

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
    await _dependencies.startTimer(
      category: _selectedCategory,
      label: _selectedLabel,
    );
    _updateSnapshot();
    await _manageWakeLock(_currentState);
  }

  Future<void> pauseTimer() async {
    await _dependencies.pauseTimer();
    _updateSnapshot();
    await _manageWakeLock(_currentState);
  }

  Future<void> stopTimer() async {
    await _dependencies.stopTimer();
    _updateSnapshot();
    await _manageWakeLock(_currentState);
  }

  Future<void> resetTimer() async {
    await _dependencies.resetTimer();
    _selectedCategory = null;
    _selectedLabel = null;
    _updateSnapshot();
    await _manageWakeLock(_currentState);
  }

  Future<void> deleteSession(int sessionId) async {
    await _dependencies.deleteSession(sessionId);
    await loadRecentSessions(); // Recharger la liste
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _dependencies.getAllCategories();
    } catch (_) {
      _categories = const [];
    }
    notifyListeners();
  }

  void updateCategoryAndLabel(entities.Category? category, String? label) {
    _selectedCategory = category;
    _selectedLabel = label;

    // Si il y a une session courante, mettre à jour ses données
    _updateCurrentSessionCategoryLabel();

    notifyListeners();
  }

  Future<void> _updateCurrentSessionCategoryLabel() async {
    try {
      await _dependencies.updateCurrentSession(
        category: _selectedCategory,
        label: _selectedLabel,
      );
      // Recharger la liste des sessions pour refléter les changements
      await loadRecentSessions();
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  Future<void> _loadCurrentSessionData() async {
    try {
      final currentSession = _dependencies.timerRepository.currentSession;
      if (currentSession != null) {
        _selectedCategory = currentSession.category;
        _selectedLabel = currentSession.label;
      }
    } catch (_) {
      // Ignorer les erreurs
    }
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

  Future<void> updateWakeLockSetting() async {
    try {
      _wakeLockEnabled = await _dependencies.getWakeLockEnabled();
      await _manageWakeLock(_currentState);
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  Future<void> _manageWakeLock(TimerState state) async {
    if (kDebugMode) {
      print('🔒 Wake lock management: enabled=$_wakeLockEnabled, state=$state');
    }

    if (!_wakeLockEnabled) {
      // Si le wake lock n'est pas activé, s'assurer qu'il est désactivé
      try {
        if (await WakelockPlus.enabled) {
          await WakelockPlus.disable();
          if (kDebugMode) print('🔒 Wake lock disabled (setting OFF)');
        }
      } catch (e) {
        if (kDebugMode) print('🔒 Error disabling wake lock: $e');
      }
      return;
    }

    try {
      if (state == TimerState.running) {
        // Activer le wake lock quand le timer tourne
        await WakelockPlus.enable();
        final isEnabled = await WakelockPlus.enabled;
        if (kDebugMode) print('🔒 Wake lock enabled: $isEnabled');
      } else {
        // Désactiver le wake lock quand le timer est pausé ou arrêté
        if (await WakelockPlus.enabled) {
          await WakelockPlus.disable();
          if (kDebugMode) print('🔒 Wake lock disabled (timer not running)');
        }
      }
    } catch (e) {
      if (kDebugMode) print('🔒 Error managing wake lock: $e');
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    // S'assurer que le wake lock est désactivé lors de la destruction
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }
}
