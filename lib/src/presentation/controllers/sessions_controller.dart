import 'package:flutter/foundation.dart';

import '../../dependency_injection/service_locator.dart';
import '../../domain/entities/timer_session.dart';
import '../../domain/entities/category.dart' as entities;

class SessionsController extends ChangeNotifier {
  SessionsController({AppDependencies? dependencies})
      : _dependencies = dependencies ?? AppDependencies.instance;

  final AppDependencies _dependencies;

  List<TimerSession> _allSessions = const [];
  List<TimerSession> _filteredSessions = const [];
  List<entities.Category> _categories = const [];
  bool _isLoading = true;

  // Filtres
  DateTime? _startDate;
  DateTime? _endDate;
  entities.Category? _selectedCategory;

  List<TimerSession> get sessions => _filteredSessions;
  List<entities.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  entities.Category? get selectedCategory => _selectedCategory;
  int get resultsCount => _filteredSessions.length;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allSessions = await _dependencies.getAllSessions();
      _allSessions = allSessions.where((session) => !session.isRunning).toList();
      _categories = await _dependencies.getAllCategories();
      _applyFilters();
    } catch (_) {
      _allSessions = const [];
      _filteredSessions = const [];
      _categories = const [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(entities.Category? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _startDate = null;
    _endDate = null;
    _selectedCategory = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredSessions = _allSessions.where((session) {
      // Filtre par date
      if (_startDate != null) {
        final sessionDate = DateTime(session.startedAt.year, session.startedAt.month, session.startedAt.day);
        final filterStartDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (sessionDate.isBefore(filterStartDate)) return false;
      }

      if (_endDate != null) {
        final sessionDate = DateTime(session.startedAt.year, session.startedAt.month, session.startedAt.day);
        final filterEndDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        if (sessionDate.isAfter(filterEndDate)) return false;
      }

      // Filtre par catégorie
      if (_selectedCategory != null) {
        if (session.category?.id != _selectedCategory!.id) return false;
      }

      return true;
    }).toList();
  }


  Future<void> deleteSession(TimerSession session) async {
    final id = session.id;
    if (id == null) return;
    await _dependencies.deleteSession(id);
    await loadSessions();
  }
}
