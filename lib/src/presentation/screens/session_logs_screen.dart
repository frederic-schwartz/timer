import 'package:flutter/material.dart';

import '../../domain/entities/session_log.dart';
import '../../domain/entities/timer_session.dart';
import '../controllers/session_logs_controller.dart';
import '../widgets/glass_card.dart';
import '../widgets/platform_map.dart';

class SessionLogsScreen extends StatefulWidget {
  final TimerSession session;

  const SessionLogsScreen({super.key, required this.session});

  @override
  State<SessionLogsScreen> createState() => _SessionLogsScreenState();
}

class _SessionLogsScreenState extends State<SessionLogsScreen> {
  late final SessionLogsController _controller;
  late TimerSession _session;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = SessionLogsController();
    _controller.addListener(_onControllerChanged);
    _session = widget.session;
    if (_session.id != null) {
      _controller.loadLogs(_session.id!);
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

  Future<void> _editLog(SessionLog log) async {
    final newTimestamp = await _pickDateTime(
      initial: log.timestamp,
      title: 'Nouvelle heure',
    );
    if (newTimestamp == null) return;

    final updatedLog = log.copyWith(timestamp: newTimestamp);
    await _controller.updateLog(updatedLog);

    if (_session.id != null) {
      await _controller.loadLogs(_session.id!);
    }

    final recalculated = _recalculateSessionFromLogs(
      _session,
      _controller.logs,
    );

    if (recalculated.endTime != null &&
        recalculated.endTime!.isBefore(recalculated.startTime)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'L\'heure de fin doit être postérieure à l\'heure de début.',
          ),
        ),
      );
      return;
    }

    final updatedSession = await _controller.updateSessionTimes(
      session: _session,
      startTime: recalculated.startTime,
      endTime: recalculated.endTime,
      totalPausedDuration: Duration(
        milliseconds: recalculated.totalPausedDuration,
      ),
      isRunning: recalculated.isRunning,
      isPaused: recalculated.isPaused,
    );

    await _controller.refreshTimerService();

    if (!mounted) return;

    setState(() {
      _session = updatedSession;
      _hasChanges = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Horodatage mis à jour.')));
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initial,
    required String title,
  }) async {
    if (!mounted) return null;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: title,
    );
    if (date == null) {
      return null;
    }

    if (!mounted) return null;

    // ignore: use_build_context_synchronously
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: title,
    );
    if (time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      initial.second,
      initial.millisecond,
      initial.microsecond,
    );
  }

  TimerSession _recalculateSessionFromLogs(
    TimerSession base,
    List<SessionLog> logs,
  ) {
    if (logs.isEmpty) {
      return base;
    }

    final sorted = [...logs]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    DateTime startTime = base.startTime;
    DateTime? endTime = base.endTime;
    int totalPausedMs = 0;
    DateTime? currentPauseStart;

    for (final log in sorted) {
      switch (log.action) {
        case SessionAction.start:
          startTime = log.timestamp;
          break;
        case SessionAction.pause:
          currentPauseStart = log.timestamp;
          break;
        case SessionAction.resume:
          if (currentPauseStart != null) {
            totalPausedMs += log.timestamp
                .difference(currentPauseStart)
                .inMilliseconds;
            currentPauseStart = null;
          }
          break;
        case SessionAction.stop:
          endTime = log.timestamp;
          if (currentPauseStart != null) {
            totalPausedMs += log.timestamp
                .difference(currentPauseStart)
                .inMilliseconds;
            currentPauseStart = null;
          }
          break;
        case SessionAction.resumeSession:
          break;
      }
    }

    if (currentPauseStart != null && endTime != null) {
      totalPausedMs += endTime.difference(currentPauseStart).inMilliseconds;
      currentPauseStart = null;
    }

    return base.copyWith(
      startTime: startTime,
      endTime: endTime,
      totalPausedDuration: totalPausedMs,
      isRunning: endTime == null,
      isPaused: currentPauseStart != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _controller.logs;

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: const Text('Détail des logs'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session du ${_formatDateTime(_session.startTime)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Durée totale',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDuration(_session.currentDuration),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (_session.totalPausedDuration > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Temps de pause',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDuration(
                                      Duration(
                                        milliseconds:
                                            _session.totalPausedDuration,
                                      ),
                                    ),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.secondary,
                                        ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Historique des actions (${logs.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : logs.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun log disponible pour cette session',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: logs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final log = logs[index];

                              return GlassCard(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _getActionColor(
                                          log.action,
                                        ).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getActionIcon(log.action),
                                        color: _getActionColor(log.action),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDateTime(log.timestamp),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            log.action.displayName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: _getActionColor(
                                                    log.action,
                                                  ),
                                                ),
                                          ),
                                          if (log.details != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                log.details!,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          if (log.latitude != null &&
                                              log.longitude != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                'Position: ${log.latitude!.toStringAsFixed(5)}, ${log.longitude!.toStringAsFixed(5)}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (log.latitude != null &&
                                            log.longitude != null)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.map_outlined,
                                            ),
                                            tooltip: 'Voir sur la carte',
                                            onPressed: () =>
                                                _showLogLocation(log),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          tooltip: 'Modifier l\'heure',
                                          onPressed: () => _editLog(log),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogLocation(SessionLog log) {
    if (log.latitude == null || log.longitude == null) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.action.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: PlatformMap(
                  center: PlatformMapMarker(
                    latitude: log.latitude!,
                    longitude: log.longitude!,
                  ),
                  markers: [
                    PlatformMapMarker(
                      latitude: log.latitude!,
                      longitude: log.longitude!,
                    ),
                  ],
                  zoom: 15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Coordonnées: ${log.latitude!.toStringAsFixed(5)}, ${log.longitude!.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
