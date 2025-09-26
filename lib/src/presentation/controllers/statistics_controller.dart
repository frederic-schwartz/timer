import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/timer_session.dart';
import '../../domain/entities/category.dart' as entities;

enum TimePeriod { daily, weekly, monthly, yearly }

class CategoryStat {
  final entities.Category? category;
  final Duration totalDuration;
  final Duration totalPauseDuration;
  final int sessionCount;

  CategoryStat({
    required this.category,
    required this.totalDuration,
    required this.totalPauseDuration,
    required this.sessionCount,
  });
}

class TimePeriodStat {
  final String label;
  final Duration totalDuration;
  final Duration totalPauseDuration;
  final int sessionCount;
  final int periodIndex; // 0-6 pour semaine, 0-30 pour mois, 0-11 pour année

  TimePeriodStat({
    required this.label,
    required this.totalDuration,
    required this.totalPauseDuration,
    required this.sessionCount,
    required this.periodIndex,
  });
}

class StatisticsController extends ChangeNotifier {
  StatisticsController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  bool _isLoading = true;
  TimePeriod _selectedPeriod = TimePeriod.monthly;
  DateTime _currentPeriodDate = DateTime.now(); // Date de référence pour la période courante
  List<TimerSession> _allSessions = const []; // Toutes les sessions
  List<TimerSession> _filteredSessions = const []; // Sessions filtrées par période
  List<CategoryStat> _categoryStats = const [];
  List<TimePeriodStat> _timePeriodStats = const [];
  Duration _totalDuration = Duration.zero;
  Duration _totalPauseDuration = Duration.zero;

  bool get isLoading => _isLoading;
  TimePeriod get selectedPeriod => _selectedPeriod;
  DateTime get currentPeriodDate => _currentPeriodDate;
  List<CategoryStat> get categoryStats => _categoryStats;
  List<TimePeriodStat> get timePeriodStats => _timePeriodStats;
  Duration get totalDuration => _totalDuration;
  Duration get totalPauseDuration => _totalPauseDuration;

  Future<void> initialize() async {
    await loadStatistics();
  }

  Future<void> loadStatistics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allSessions = await _dependencies.getAllSessions();
      _allSessions = allSessions.where((session) => !session.isRunning).toList();

      _filterSessionsByPeriod();
      _calculateCategoryStats();
      _calculateTimePeriodStats();
      _calculateTotals();
    } catch (_) {
      _allSessions = const [];
      _filteredSessions = const [];
      _categoryStats = const [];
      _timePeriodStats = const [];
      _totalDuration = Duration.zero;
      _totalPauseDuration = Duration.zero;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(TimePeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      _currentPeriodDate = DateTime.now(); // Reset à la période courante
      _filterSessionsByPeriod();
      _calculateCategoryStats();
      _calculateTimePeriodStats();
      _calculateTotals();
      notifyListeners();
    }
  }

  void goToPreviousPeriod() {
    if (!canGoToPreviousPeriod()) return;

    DateTime newDate;
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month, _currentPeriodDate.day - 1);
        break;
      case TimePeriod.weekly:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month, _currentPeriodDate.day - 7);
        break;
      case TimePeriod.monthly:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month - 1, 1);
        break;
      case TimePeriod.yearly:
        newDate = DateTime(_currentPeriodDate.year - 1, 1, 1);
        break;
    }

    _currentPeriodDate = newDate;
    _filterSessionsByPeriod();
    _calculateCategoryStats();
    _calculateTimePeriodStats();
    _calculateTotals();
    notifyListeners();
  }

  void goToNextPeriod() {
    if (!canGoToNextPeriod()) return;

    DateTime newDate;
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month, _currentPeriodDate.day + 1);
        break;
      case TimePeriod.weekly:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month, _currentPeriodDate.day + 7);
        break;
      case TimePeriod.monthly:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month + 1, 1);
        break;
      case TimePeriod.yearly:
        newDate = DateTime(_currentPeriodDate.year + 1, 1, 1);
        break;
    }

    _currentPeriodDate = newDate;
    _filterSessionsByPeriod();
    _calculateCategoryStats();
    _calculateTimePeriodStats();
    _calculateTotals();
    notifyListeners();
  }

  bool canGoToPreviousPeriod() {
    // Toujours possible d'aller dans le passé
    return true;
  }

  bool canGoToNextPeriod() {
    // On peut naviguer vers le futur tant qu'on ne dépasse pas aujourd'hui
    DateTime newDate;
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month, _currentPeriodDate.day + 1);
        break;
      case TimePeriod.weekly:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month, _currentPeriodDate.day + 7);
        break;
      case TimePeriod.monthly:
        newDate = DateTime(_currentPeriodDate.year, _currentPeriodDate.month + 1, 1);
        break;
      case TimePeriod.yearly:
        newDate = DateTime(_currentPeriodDate.year + 1, 1, 1);
        break;
    }

    final now = DateTime.now();
    return newDate.isBefore(now) || _isSamePeriod(newDate, now);
  }


  bool _isSamePeriod(DateTime date1, DateTime date2) {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
      case TimePeriod.weekly:
        final week1Start = _getWeekStart(date1);
        final week2Start = _getWeekStart(date2);
        return week1Start.isAtSameMomentAs(week2Start);
      case TimePeriod.monthly:
        return date1.year == date2.year && date1.month == date2.month;
      case TimePeriod.yearly:
        return date1.year == date2.year;
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - weekday + 1);
  }

  void _filterSessionsByPeriod() {
    final (startDate, endDate) = _getPeriodRange(_currentPeriodDate);

    _filteredSessions = _allSessions.where((session) {
      return (session.startedAt.isAfter(startDate) ||
             session.startedAt.isAtSameMomentAs(startDate)) &&
             session.startedAt.isBefore(endDate);
    }).toList();
  }

  (DateTime, DateTime) _getPeriodRange(DateTime referenceDate) {
    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriod) {
      case TimePeriod.daily:
        startDate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case TimePeriod.weekly:
        final weekday = referenceDate.weekday;
        startDate = DateTime(referenceDate.year, referenceDate.month, referenceDate.day - weekday + 1);
        endDate = startDate.add(const Duration(days: 7));
        break;
      case TimePeriod.monthly:
        startDate = DateTime(referenceDate.year, referenceDate.month, 1);
        endDate = DateTime(referenceDate.year, referenceDate.month + 1, 1);
        break;
      case TimePeriod.yearly:
        startDate = DateTime(referenceDate.year, 1, 1);
        endDate = DateTime(referenceDate.year + 1, 1, 1);
        break;
    }

    return (startDate, endDate);
  }

  void _calculateCategoryStats() {
    final Map<int?, CategoryStat> statsMap = {};

    for (final session in _filteredSessions) {
      final categoryId = session.category?.id;

      if (statsMap.containsKey(categoryId)) {
        final existing = statsMap[categoryId]!;
        statsMap[categoryId] = CategoryStat(
          category: existing.category,
          totalDuration: existing.totalDuration + session.totalDuration,
          totalPauseDuration: existing.totalPauseDuration +
                             Duration(milliseconds: session.totalPauseDuration),
          sessionCount: existing.sessionCount + 1,
        );
      } else {
        statsMap[categoryId] = CategoryStat(
          category: session.category,
          totalDuration: session.totalDuration,
          totalPauseDuration: Duration(milliseconds: session.totalPauseDuration),
          sessionCount: 1,
        );
      }
    }

    _categoryStats = statsMap.values.toList()
      ..sort((a, b) => b.totalDuration.compareTo(a.totalDuration));
  }

  void _calculateTimePeriodStats() {
    switch (_selectedPeriod) {
      case TimePeriod.daily:
        // Pour le mode jour, on ne montre rien de spécial (ou on peut montrer les heures)
        _timePeriodStats = const [];
        break;
      case TimePeriod.weekly:
        _calculateWeeklyStats();
        break;
      case TimePeriod.monthly:
        _calculateMonthlyStats();
        break;
      case TimePeriod.yearly:
        _calculateYearlyStats();
        break;
    }
  }

  void _calculateWeeklyStats() {
    final Map<int, TimePeriodStat> statsMap = {};
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    // Initialiser tous les jours de la semaine à 0
    for (int i = 0; i < 7; i++) {
      statsMap[i] = TimePeriodStat(
        label: weekdays[i],
        totalDuration: Duration.zero,
        totalPauseDuration: Duration.zero,
        sessionCount: 0,
        periodIndex: i,
      );
    }

    // Calculer les stats pour chaque session
    for (final session in _filteredSessions) {
      final weekdayIndex = session.startedAt.weekday - 1; // 0=lundi, 6=dimanche
      final existing = statsMap[weekdayIndex]!;

      statsMap[weekdayIndex] = TimePeriodStat(
        label: existing.label,
        totalDuration: existing.totalDuration + session.totalDuration,
        totalPauseDuration: existing.totalPauseDuration + Duration(milliseconds: session.totalPauseDuration),
        sessionCount: existing.sessionCount + 1,
        periodIndex: weekdayIndex,
      );
    }

    _timePeriodStats = List.from(statsMap.values);
  }

  void _calculateMonthlyStats() {
    final Map<int, TimePeriodStat> statsMap = {};
    final (startDate, endDate) = _getPeriodRange(_currentPeriodDate);
    final daysInMonth = DateTime(startDate.year, startDate.month + 1, 0).day;

    // Initialiser tous les jours du mois à 0
    for (int i = 1; i <= daysInMonth; i++) {
      statsMap[i] = TimePeriodStat(
        label: i.toString(),
        totalDuration: Duration.zero,
        totalPauseDuration: Duration.zero,
        sessionCount: 0,
        periodIndex: i - 1, // 0-indexed pour les graphiques
      );
    }

    // Calculer les stats pour chaque session
    for (final session in _filteredSessions) {
      final dayOfMonth = session.startedAt.day;
      final existing = statsMap[dayOfMonth]!;

      statsMap[dayOfMonth] = TimePeriodStat(
        label: existing.label,
        totalDuration: existing.totalDuration + session.totalDuration,
        totalPauseDuration: existing.totalPauseDuration + Duration(milliseconds: session.totalPauseDuration),
        sessionCount: existing.sessionCount + 1,
        periodIndex: dayOfMonth - 1,
      );
    }

    _timePeriodStats = List.generate(daysInMonth, (i) => statsMap[i + 1]!);
  }

  void _calculateYearlyStats() {
    final Map<int, TimePeriodStat> statsMap = {};

    // Initialiser tous les mois de l'année à 0
    for (int i = 0; i < 12; i++) {
      statsMap[i] = TimePeriodStat(
        label: (i + 1).toString(), // 1, 2, 3, ..., 12
        totalDuration: Duration.zero,
        totalPauseDuration: Duration.zero,
        sessionCount: 0,
        periodIndex: i,
      );
    }

    // Calculer les stats pour chaque session
    for (final session in _filteredSessions) {
      final monthIndex = session.startedAt.month - 1; // 0=janvier, 11=décembre
      final existing = statsMap[monthIndex]!;

      statsMap[monthIndex] = TimePeriodStat(
        label: existing.label,
        totalDuration: existing.totalDuration + session.totalDuration,
        totalPauseDuration: existing.totalPauseDuration + Duration(milliseconds: session.totalPauseDuration),
        sessionCount: existing.sessionCount + 1,
        periodIndex: monthIndex,
      );
    }

    _timePeriodStats = List.from(statsMap.values);
  }

  void _calculateTotals() {
    _totalDuration = _filteredSessions.fold(Duration.zero, (sum, session) => sum + session.totalDuration);
    _totalPauseDuration = _filteredSessions.fold(Duration.zero, (sum, session) =>
        sum + Duration(milliseconds: session.totalPauseDuration));
  }

  String getPeriodLabel() {
    final (startDate, endDate) = _getPeriodRange(_currentPeriodDate);
    final now = DateTime.now();
    final isCurrentPeriod = _isSamePeriod(_currentPeriodDate, now);

    switch (_selectedPeriod) {
      case TimePeriod.daily:
        if (isCurrentPeriod) {
          return 'Aujourd\'hui';
        }
        return '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
      case TimePeriod.weekly:
        if (isCurrentPeriod) {
          return 'Cette semaine';
        }
        final endOfWeek = endDate.subtract(const Duration(days: 1));
        return 'Semaine du ${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')} au ${endOfWeek.day.toString().padLeft(2, '0')}/${endOfWeek.month.toString().padLeft(2, '0')}';
      case TimePeriod.monthly:
        if (isCurrentPeriod) {
          return 'Ce mois';
        }
        final months = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
        return '${months[startDate.month]} ${startDate.year}';
      case TimePeriod.yearly:
        if (isCurrentPeriod) {
          return 'Cette année';
        }
        return '${startDate.year}';
    }
  }
}