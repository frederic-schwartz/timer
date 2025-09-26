import 'package:flutter/foundation.dart';

import '../../core/backup/icloud_backup_service.dart';
import '../../data/datasources/session_local_data_source.dart';
import '../../data/datasources/category_local_data_source.dart';
import '../repositories/session_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/settings_repository.dart';
import '../entities/timer_session.dart';
import '../entities/category.dart' as entities;

class RestoreAppData {
  final ICloudBackupService _backupService;
  final SessionRepository _sessionRepository;
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final SessionLocalDataSource _sessionDataSource;
  final CategoryLocalDataSource _categoryDataSource;

  RestoreAppData(
    this._backupService,
    this._sessionRepository,
    this._categoryRepository,
    this._settingsRepository,
    this._sessionDataSource,
    this._categoryDataSource,
  );

  Future<bool> call() async {
    try {
      final backupData = await _backupService.loadBackup();
      if (backupData == null) {
        if (kDebugMode) {
          print('🔒 RestoreAppData: Aucune sauvegarde trouvée');
        }
        return false;
      }

      if (kDebugMode) {
        print('🔒 RestoreAppData: Début de la restauration');
      }

      // Forcer l'initialisation de la base de données avant toute opération
      await _sessionDataSource.ensureInitialized();
      await _categoryDataSource.ensureInitialized();

      if (kDebugMode) {
        print('🔒 RestoreAppData: Base de données initialisée');
      }

      final sessionsData = (backupData['sessions'] as List<dynamic>?) ?? [];
      final categoriesData = (backupData['categories'] as List<dynamic>?) ?? [];
      final settings = backupData['settings'] as Map<String, dynamic>? ?? {};

      // Vérifier d'abord s'il y a déjà des sessions utilisateur (ignorer les catégories par défaut)
      final existingSessions = await _sessionRepository.getAllSessions();
      if (existingSessions.isNotEmpty) {
        if (kDebugMode) {
          print('🔒 RestoreAppData: Des sessions existent déjà (${existingSessions.length} sessions), restauration annulée');
        }
        return false;
      }

      // Récupérer les catégories existantes pour éviter les doublons
      final existingCategories = await _categoryRepository.getAllCategories();

      // Restaurer les catégories d'abord (sans l'ID pour éviter les conflits)
      final categoryMap = <int, entities.Category>{};
      for (final categoryJson in categoriesData) {
        final categoryData = categoryJson as Map<String, dynamic>;
        final originalId = categoryData['id'] as int?;
        final categoryName = categoryData['name'] as String;
        final categoryColor = categoryData['color'] as String;

        // Vérifier si cette catégorie existe déjà
        final existingCategory = existingCategories.firstWhere(
          (cat) => cat.name == categoryName && cat.color == categoryColor,
          orElse: () => entities.Category(id: null, name: '', color: ''),
        );

        entities.Category targetCategory;
        if (existingCategory.id != null) {
          // Utiliser la catégorie existante
          targetCategory = existingCategory;
          if (kDebugMode) {
            print('🔒 RestoreAppData: Catégorie existante réutilisée - $categoryName');
          }
        } else {
          // Créer une nouvelle catégorie
          final category = entities.Category(
            id: null, // Laisser la base auto-assigner l'ID
            name: categoryName,
            color: categoryColor,
          );
          targetCategory = await _categoryRepository.insertCategory(category);
          if (kDebugMode) {
            print('🔒 RestoreAppData: Nouvelle catégorie créée - $categoryName (ID: ${targetCategory.id})');
          }
        }

        if (originalId != null) {
          categoryMap[originalId] = targetCategory; // Mapper l'ancien ID vers la catégorie
        }
      }

      // Restaurer les sessions
      for (final sessionJson in sessionsData) {
        final sessionData = sessionJson as Map<String, dynamic>;
        final categoryId = sessionData['categoryId'] as int?;
        final category = categoryId != null ? categoryMap[categoryId] : null;

        final session = TimerSession(
          id: null, // Laisser la base auto-assigner l'ID
          startedAt: DateTime.parse(sessionData['startedAt'] as String),
          endedAt: sessionData['endedAt'] != null
              ? DateTime.parse(sessionData['endedAt'] as String)
              : null,
          totalPauseDuration: sessionData['totalPauseDuration'] as int? ?? 0,
          isPaused: sessionData['isPaused'] as bool? ?? false,
          category: category,
          label: sessionData['label'] as String?,
        );

        await _sessionRepository.insertSession(session);
        if (kDebugMode) {
          print('🔒 RestoreAppData: Session restaurée - ${session.startedAt}');
        }
      }

      // Restaurer les paramètres
      final recentSessionsCount = settings['recentSessionsCount'] as int?;
      if (recentSessionsCount != null) {
        await _settingsRepository.setRecentSessionsCount(recentSessionsCount);
      }

      final wakeLockEnabled = settings['wakeLockEnabled'] as bool?;
      if (wakeLockEnabled != null) {
        await _settingsRepository.setWakeLockEnabled(wakeLockEnabled);
      }

      if (kDebugMode) {
        print('🔒 RestoreAppData: Restauration terminée - ${sessionsData.length} sessions, ${categoriesData.length} catégories');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🔒 RestoreAppData: Erreur lors de la restauration - $e');
      }
      return false;
    }
  }
}