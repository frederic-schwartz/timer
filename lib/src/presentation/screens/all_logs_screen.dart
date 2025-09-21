import 'package:flutter/material.dart';
import '../../domain/entities/session_log.dart';
import '../controllers/all_logs_controller.dart';
import '../widgets/glass_card.dart';
import '../widgets/platform_map.dart';

class AllLogsScreen extends StatefulWidget {
  const AllLogsScreen({super.key});

  @override
  State<AllLogsScreen> createState() => _AllLogsScreenState();
}

class _AllLogsScreenState extends State<AllLogsScreen> {
  late final AllLogsController _controller;
  bool _hasChanges = false;

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.clearAllLogs();
        _hasChanges = true;
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

  Future<void> _showLogDetails(SessionLog log) async {
    final session = _controller.sessionForLog(log);

    await showModalBottomSheet<void>(
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
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 8),
                  Text(_formatDateTime(log.timestamp)),
                ],
              ),
              if (session != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text('Session du ${_formatDateTime(session.startTime)}'),
                  ],
                ),
              ],
              if (log.details != null && log.details!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  log.details!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (log.latitude != null && log.longitude != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
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
                const SizedBox(height: 8),
                Text(
                  'Coordonnées: ${log.latitude!.toStringAsFixed(5)}, '
                  '${log.longitude!.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({required String label, required String value}) {
    final theme = Theme.of(context);
    final isSelected = _controller.filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _controller.setFilter(value),
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.4),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : theme.colorScheme.outline.withValues(alpha: 0.2),
      ),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _controller.filteredLogs;

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
          title: const Text('Tous les logs'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.colorScheme.onPrimary,
          actions: [
            IconButton(
              onPressed: () => _clearAllLogs(context),
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Supprimer tous les logs',
            ),
          ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildFilterChip(label: 'Tous', value: 'all'),
                        _buildFilterChip(label: 'Démarrages', value: 'start'),
                        _buildFilterChip(label: 'Pauses', value: 'pause'),
                        _buildFilterChip(label: 'Reprises', value: 'resume'),
                        _buildFilterChip(label: 'Arrêts', value: 'stop'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : logs.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun log disponible',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _controller.loadData,
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: logs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                final session = _controller.sessionForLog(log);

                                return GlassCard(
                                  padding: const EdgeInsets.all(18),
                                  onTap: () => _showLogDetails(log),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              log.action.displayName,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: _getActionColor(
                                                      log.action,
                                                    ),
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDateTime(log.timestamp),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.7),
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
                                                  top: 6,
                                                ),
                                                child: Text(
                                                  'Position: ${log.latitude!.toStringAsFixed(5)}, ${log.longitude!.toStringAsFixed(5)}',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
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
                                            if (session != null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Session du ${_formatDateTime(session.startTime)}',
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
                                              if (session.endTime != null)
                                                Text(
                                                  'Durée: ${_formatDuration(session.currentDuration)}',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                      ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded),
                                    ],
                                  ),
                                );
                              },
                            ),
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
}
