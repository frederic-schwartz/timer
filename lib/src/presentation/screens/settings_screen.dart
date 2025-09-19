import 'package:flutter/material.dart';

import '../controllers/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;

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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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

  @override
  Widget build(BuildContext context) {
    final count = _controller.recentSessionsCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réglages'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Affichage',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Sessions récentes'),
                        subtitle: Text('Afficher $count sessions sur l\'écran principal'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: count > SettingsController.minRecentSessions
                                  ? () => _controller.decreaseRecentSessions()
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: count < SettingsController.maxRecentSessions
                                  ? () => _controller.increaseRecentSessions()
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Données',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: const Text('Supprimer tout l\'historique'),
                        subtitle: const Text('Efface toutes les sessions terminées'),
                        onTap: () => _clearAllSessions(context),
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Informations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Version'),
                        subtitle: Text('1.0.0'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.developer_mode),
                        title: Text('Technologie'),
                        subtitle: Text('Flutter / Dart'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
