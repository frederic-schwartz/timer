import 'package:flutter/material.dart';

import '../../domain/entities/session_log.dart';
import '../controllers/all_logs_controller.dart';
import 'session_logs_screen.dart';

class AllLogsScreen extends StatefulWidget {
  const AllLogsScreen({super.key});

  @override
  State<AllLogsScreen> createState() => _AllLogsScreenState();
}

class _AllLogsScreenState extends State<AllLogsScreen> {
  late final AllLogsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AllLogsController();
    _controller.addListener(_onControllerChanged);
    _controller.loadData();
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getActionColor(SessionAction action) {
    switch (action) {
      case SessionAction.start:
        return Colors.green;
      case SessionAction.pause:
        return Colors.orange;
      case SessionAction.resume:
        return Colors.blue;
      case SessionAction.stop:
        return Colors.red;
      case SessionAction.resumeSession:
        return Colors.purple;
    }
  }

  IconData _getActionIcon(SessionAction action) {
    switch (action) {
      case SessionAction.start:
        return Icons.play_arrow;
      case SessionAction.pause:
        return Icons.pause;
      case SessionAction.resume:
        return Icons.play_arrow;
      case SessionAction.stop:
        return Icons.stop;
      case SessionAction.resumeSession:
        return Icons.restart_alt;
    }
  }

  Future<void> _clearAllLogs(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer tous les logs'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer tous les logs ? '
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
        await _controller.clearAllLogs();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tous les logs ont été supprimés'),
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

  void _showSessionDetails(SessionLog log) {
    final session = _controller.sessionForLog(log);
    if (session != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionLogsScreen(session: session),
        ),
      );
    }
  }

  Widget _buildFilterChip({required String label, required String value}) {
    return FilterChip(
      label: Text(label),
      selected: _controller.filter == value,
      onSelected: (_) => _controller.setFilter(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _controller.filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les logs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => _clearAllLogs(context),
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Supprimer tous les logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(label: 'Tous', value: 'all'),
                _buildFilterChip(label: 'Démarrages', value: 'start'),
                _buildFilterChip(label: 'Pauses', value: 'pause'),
                _buildFilterChip(label: 'Reprises', value: 'resume'),
                _buildFilterChip(label: 'Arrêts', value: 'stop'),
                _buildFilterChip(label: 'Reprise session', value: 'resume_session'),
              ],
            ),
          ),
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun log disponible',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _controller.loadData,
                        child: ListView.builder(
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final session = _controller.sessionForLog(log);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getActionColor(log.action).withValues(alpha: 0.1),
                                  child: Icon(
                                    _getActionIcon(log.action),
                                    color: _getActionColor(log.action),
                                  ),
                                ),
                                title: Text(
                                  '${log.action.displayName} • ${_formatDateTime(log.timestamp)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (log.details != null) Text(log.details!),
                                    if (session != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Session du ${_formatDateTime(session.startTime)}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      if (session.endTime != null)
                                        Text(
                                          'Durée: ${_formatDuration(session.currentDuration)}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                                onTap: () => _showSessionDetails(log),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
