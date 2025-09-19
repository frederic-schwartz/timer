import 'package:flutter/material.dart';

import '../../domain/entities/session_log.dart';
import '../../domain/entities/timer_session.dart';
import '../controllers/session_logs_controller.dart';

class SessionLogsScreen extends StatefulWidget {
  final TimerSession session;

  const SessionLogsScreen({super.key, required this.session});

  @override
  State<SessionLogsScreen> createState() => _SessionLogsScreenState();
}

class _SessionLogsScreenState extends State<SessionLogsScreen> {
  late final SessionLogsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SessionLogsController();
    _controller.addListener(_onControllerChanged);
    if (widget.session.id != null) {
      _controller.loadLogs(widget.session.id!);
    }
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
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    final logs = _controller.logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail des logs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
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
                  'Session du ${_formatDateTime(widget.session.startTime)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Durée totale',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          _formatDuration(widget.session.currentDuration),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (widget.session.totalPausedDuration > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temps de pause',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            _formatDuration(Duration(milliseconds: widget.session.totalPausedDuration)),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Historique des actions (${logs.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun log disponible pour cette session',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isLast = index == logs.length - 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _getActionColor(log.action).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _getActionIcon(log.action),
                                            color: _getActionColor(log.action),
                                          ),
                                        ),
                                        if (!isLast)
                                          Container(
                                            width: 2,
                                            height: 40,
                                            margin: const EdgeInsets.only(top: 4),
                                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDateTime(log.timestamp),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            log.action.displayName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: _getActionColor(log.action),
                                            ),
                                          ),
                                          if (log.details != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                log.details!,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
