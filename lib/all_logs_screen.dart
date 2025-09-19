import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'models/session_log.dart';
import 'models/timer_session.dart';
import 'session_logs_screen.dart';

class AllLogsScreen extends StatefulWidget {
  const AllLogsScreen({super.key});

  @override
  State<AllLogsScreen> createState() => _AllLogsScreenState();
}

class _AllLogsScreenState extends State<AllLogsScreen> {
  List<SessionLog> _logs = [];
  List<TimerSession> _sessions = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final logs = await DatabaseService.getAllLogs();
    final sessions = await DatabaseService.getAllSessions();

    setState(() {
      _logs = logs;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  List<SessionLog> get _filteredLogs {
    if (_filter == 'all') return _logs;
    return _logs.where((log) => log.action.name == _filter).toList();
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

  TimerSession? _getSessionForLog(SessionLog log) {
    try {
      return _sessions.firstWhere((session) => session.id == log.sessionId);
    } catch (e) {
      return null;
    }
  }

  void _showSessionDetails(SessionLog log) {
    final session = _getSessionForLog(log);
    if (session != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionLogsScreen(session: session),
        ),
      );
    }
  }

  Future<void> _clearAllLogs() async {
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
        await DatabaseService.deleteAllLogs();
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tous les logs ont été supprimés'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les logs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _clearAllLogs,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Supprimer tous les logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: _filter == 'all',
                  onSelected: (selected) {
                    setState(() {
                      _filter = 'all';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Démarrages'),
                  selected: _filter == 'start',
                  onSelected: (selected) {
                    setState(() {
                      _filter = 'start';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Pauses'),
                  selected: _filter == 'pause',
                  onSelected: (selected) {
                    setState(() {
                      _filter = 'pause';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Reprises'),
                  selected: _filter == 'resume',
                  onSelected: (selected) {
                    setState(() {
                      _filter = 'resume';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Arrêts'),
                  selected: _filter == 'stop',
                  onSelected: (selected) {
                    setState(() {
                      _filter = 'stop';
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Reprises session'),
                  selected: _filter == 'resume_session',
                  onSelected: (selected) {
                    setState(() {
                      _filter = 'resume_session';
                    });
                  },
                ),
              ],
            ),
          ),
          // Stats
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredLogs.length} logs ${_filter == 'all' ? 'au total' : 'filtrés'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (_filter == 'all' && _sessions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_sessions.where((s) => !s.isRunning).length} sessions terminées',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filter == 'all'
                                  ? 'Aucun log disponible'
                                  : 'Aucun log pour ce filtre',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            final session = _getSessionForLog(log);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Card(
                                elevation: 1,
                                child: InkWell(
                                  onTap: session != null ? () => _showSessionDetails(log) : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _getActionColor(log.action).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            _getActionIcon(log.action),
                                            color: _getActionColor(log.action),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    log.action.displayName,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: _getActionColor(log.action),
                                                    ),
                                                  ),
                                                  if (session != null)
                                                    Text(
                                                      'Session: ${_formatDuration(session.currentDuration)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDateTime(log.timestamp),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                              ),
                                              if (log.details != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  log.details!,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (session != null)
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
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