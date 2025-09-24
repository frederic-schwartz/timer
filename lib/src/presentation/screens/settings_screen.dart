import 'package:flutter/material.dart';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../../domain/entities/category.dart';
import '../controllers/settings_controller.dart';
import '../widgets/category_edit_dialog.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _clearAllSessions(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tout l\'historique'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les sessions ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.clearCompletedSessions();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Historique supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCategoryDialog(BuildContext context, {Category? category}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CategoryEditDialog(category: category),
    );

    if (result != null) {
      if (category != null) {
        // Modifier une catégorie existante
        final updatedCategory = category.copyWith(
          name: result['name'],
          color: result['color'],
        );
        await _controller.updateCategory(updatedCategory);
      } else {
        // Créer une nouvelle catégorie
        await _controller.addCategory(result['name'], result['color']);
      }
    }
  }

  Future<void> _deleteCategory(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la catégorie "${category.name}" ?\n\n'
          'Les sessions utilisant cette catégorie n\'auront plus de catégorie associée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && category.id != null) {
      await _controller.deleteCategory(category.id!);
    }
  }

  Future<void> _backupToICloud(BuildContext context) async {
    if (_isBackingUp) return;

    setState(() {
      _isBackingUp = true;
    });

    try {
      await _controller.backupToICloud();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sauvegarde iCloud effectuée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        final message = switch (error) {
          PlatformException e => e.message ?? 'Sauvegarde iCloud indisponible.',
          MissingPluginException _ => 'Sauvegarde iCloud indisponible sur cet appareil.',
          _ => 'Sauvegarde impossible.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _controller.recentSessionsCount;

    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.9),
        theme.colorScheme.primaryContainer.withValues(alpha: 0.85),
        theme.colorScheme.surface,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Réglages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Text(
                      'Personnalisez votre expérience',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Affichage',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (Platform.isIOS) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.cloud_upload,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: const Text('Sauvegarder sur iCloud'),
                              subtitle: const Text(
                                'Exporte vos sessions et catégories',
                              ),
                              trailing: _isBackingUp
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : null,
                              onTap: _isBackingUp ? null : () => _backupToICloud(context),
                            ),
                            const SizedBox(height: 12),
                          ],
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.history,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: const Text('Dernières sessions'),
                            subtitle: Text(
                              'Afficher $count sessions sur l\'écran principal',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed:
                                      count >
                                          SettingsController.minRecentSessions
                                      ? () =>
                                            _controller.decreaseRecentSessions()
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                Text(
                                  '$count',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      count <
                                          SettingsController.maxRecentSessions
                                      ? () =>
                                            _controller.increaseRecentSessions()
                                      : null,
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Catégories',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showCategoryDialog(context),
                                icon: const Icon(Icons.add),
                                tooltip: 'Ajouter une catégorie',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_controller.categories.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('Aucune catégorie'),
                              ),
                            )
                          else
                            ...(_controller.categories.map((category) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.label,
                                  color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000),
                                ),
                              ),
                              title: Text(category.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _showCategoryDialog(context, category: category),
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteCategory(context, category),
                                    icon: const Icon(Icons.delete),
                                    color: theme.colorScheme.error,
                                    tooltip: 'Supprimer',
                                  ),
                                ],
                              ),
                            ))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Données',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.delete_forever,
                                color: theme.colorScheme.error,
                              ),
                            ),
                            title: const Text('Supprimer tout l\'historique'),
                            subtitle: const Text(
                              'Efface toutes les sessions terminées',
                            ),
                            onTap: () => _clearAllSessions(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
