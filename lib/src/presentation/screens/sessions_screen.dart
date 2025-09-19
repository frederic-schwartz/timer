import 'package:flutter/material.dart';

import '../../domain/entities/timer_session.dart';
import '../controllers/sessions_controller.dart';
import 'session_logs_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late final SessionsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SessionsController();
    _controller.addListener(_onControllerChanged);
    _controller.loadSessions();
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resumeSession(TimerSession session) async {
    await _controller.resumeSession(session);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteSession(TimerSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la session'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteSession(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _controller.sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des sessions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune session terminée',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _controller.loadSessions,
                  child: ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final duration = session.currentDuration;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.timer,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          title: Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Début: ${_formatDateTime(session.startTime)}'),
                              if (session.endTime != null)
                                Text('Fin: ${_formatDateTime(session.endTime!)}'),
                              if (session.totalPausedDuration > 0)
                                Text(
                                  'Temps de pause: ${_formatDuration(Duration(milliseconds: session.totalPausedDuration))}',
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'resume',
                                child: const Row(
                                  children: [
                                    Icon(Icons.play_arrow),
                                    SizedBox(width: 8),
                                    Text('Reprendre'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'logs',
                                child: const Row(
                                  children: [
                                    Icon(Icons.list_alt),
                                    SizedBox(width: 8),
                                    Text('Voir les logs'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Supprimer'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'resume') {
                                _resumeSession(session);
                              } else if (value == 'logs') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SessionLogsScreen(session: session),
                                  ),
                                );
                              } else if (value == 'delete') {
                                _deleteSession(session);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
