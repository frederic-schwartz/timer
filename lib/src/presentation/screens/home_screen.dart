import 'package:flutter/material.dart';

import '../../domain/entities/timer_session.dart';
import '../../domain/entities/timer_state.dart';
import '../controllers/home_controller.dart';
import '../widgets/category_selection_dialog.dart';
import 'about_screen.dart';
import 'edit_session_screen.dart';
import 'sessions_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;
  late final ScrollController _scrollController;
  TimerState? _previousState;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _scrollController = ScrollController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  void _onControllerChanged() {
    if (mounted) {
      final currentState = _controller.currentState;

      // Si le timer vient d'être stoppé (transition vers finished), remonter la liste au début
      if (_previousState != null &&
          _previousState != TimerState.finished &&
          currentState == TimerState.finished &&
          _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      _previousState = currentState;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    await _controller.startTimer();
  }

  Future<void> _pauseTimer() async {
    await _controller.pauseTimer();
  }


  Future<void> _stopTimer() async {
    await _controller.stopTimer();
  }

  Future<void> _editSession(TimerSession session) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSessionScreen(session: session),
      ),
    );

    if (result == true) {
      // Session modifiée, recharger les données
      await _controller.loadRecentSessions();
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

    if (confirmed == true && session.id != null) {
      await _controller.deleteSession(session.id!);
    }
  }

  Future<void> _resetTimer() async {
    await _controller.resetTimer();
  }

  Future<void> _showCategoryDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CategorySelectionDialog(
        categories: _controller.categories,
        selectedCategory: _controller.selectedCategory,
        currentLabel: _controller.selectedLabel,
      ),
    );

    if (result != null) {
      _controller.updateCategoryAndLabel(
        result['category'],
        result['label'],
      );
    }
  }

  Color _stateColor(TimerState state, ThemeData theme) {
    switch (state) {
      case TimerState.running:
        return theme.colorScheme.primary;
      case TimerState.paused:
        return theme.colorScheme.secondary;
      case TimerState.ready:
        return theme.colorScheme.tertiary;
      case TimerState.stopped:
        return theme.colorScheme.primary;
      case TimerState.finished:
        return theme.colorScheme.tertiary;
    }
  }

  String _stateLabel(TimerState state) {
    switch (state) {
      case TimerState.running:
        return 'En cours';
      case TimerState.paused:
        return 'En pause';
      case TimerState.ready:
        return 'Prêt à reprendre';
      case TimerState.stopped:
        return 'Arrêté';
      case TimerState.finished:
        return 'Terminé';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Drawer _buildDrawer(ThemeData theme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Tockee',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SessionsScreen(),
                ),
              );
              await _controller.loadRecentSessions();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Réglages'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              await _controller.loadRecentSessions();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimerHero(BuildContext context, TimerState state) {
    final theme = Theme.of(context);
    final accent = _stateColor(state, theme);
    final pauseLabel = _formatDuration(_controller.totalPauseRealTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.92),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StateBadge(label: _stateLabel(state), color: accent),
              IconButton(
                onPressed: () => _showCategoryDialog(context),
                icon: const Icon(Icons.label_outline),
                iconSize: 20,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: Text(
              _formatDuration(_controller.currentDuration),
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 145,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Pause',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pauseLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (state == TimerState.paused && _controller.totalPause > Duration.zero) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '+${_formatDuration(_controller.currentPauseDuration)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_controller.selectedCategory != null || (_controller.selectedLabel != null && _controller.selectedLabel!.isNotEmpty)) ...[
            const SizedBox(height: 16),
            _buildCategoryLabelInfo(context, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryLabelInfo(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        if (_controller.selectedCategory != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Color(int.parse(_controller.selectedCategory!.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(int.parse(_controller.selectedCategory!.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(int.parse(_controller.selectedCategory!.color.substring(1), radix: 16) + 0xFF000000),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _controller.selectedCategory!.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Color(int.parse(_controller.selectedCategory!.color.substring(1), radix: 16) + 0xFF000000),
                  ),
                ),
              ],
            ),
          ),
          if (_controller.selectedLabel != null && _controller.selectedLabel!.isNotEmpty) const SizedBox(width: 8),
        ],
        if (_controller.selectedLabel != null && _controller.selectedLabel!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              _controller.selectedLabel!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControls(BuildContext context, TimerState state) {
    final theme = Theme.of(context);
    final isRunning = state == TimerState.running;
    final isPaused = state == TimerState.paused;
    final isFinished = state == TimerState.finished;
    final primaryLabel = isRunning
        ? 'Pause'
        : isPaused
            ? 'Reprendre'
            : 'Démarrer';

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isFinished ? null : (isRunning ? _pauseTimer : _startTimer),
            icon: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 26),
            label: Text(primaryLabel),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              backgroundColor: _stateColor(state, theme),
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton.icon(
            onPressed: (state == TimerState.finished)
                ? _resetTimer
                : (isRunning || isPaused ? _stopTimer : null),
            icon: Icon(
              isFinished ? Icons.refresh_rounded : Icons.stop_rounded,
              size: 26
            ),
            label: Text(isFinished ? 'Reset' : 'Arrêter'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              backgroundColor: (state == TimerState.ready || isFinished)
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.errorContainer,
              foregroundColor: (state == TimerState.ready || isFinished)
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onErrorContainer,
              disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              disabledForegroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSessionsList(BuildContext context, List<TimerSession> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Pas encore de session récente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(overscroll: false, physics: const BouncingScrollPhysics()),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == sessions.length - 1 ? 0 : 12),
            child: _RecentSessionCard(
              session: session,
              onEdit: () => _editSession(session),
              onDelete: () => _deleteSession(session),
              durationLabel: _formatDuration(session.totalDuration),
              startLabel: _formatDateTime(session.startedAt),
              pauseLabel: session.totalPauseDuration > 0
                  ? _formatDuration(Duration(milliseconds: session.totalPauseDuration))
                  : null,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _controller.currentState;

    final backgroundGradient = LinearGradient(
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
        title: const Text('Tockee'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onPrimary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      drawer: _buildDrawer(theme),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTimerHero(context, state),
                          const SizedBox(height: 24),
                          _buildControls(context, state),
                          const SizedBox(height: 32),
                          Text(
                            'Sessions récentes',
                            style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildRecentSessionsList(
                        context,
                        _controller.recentSessions,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, size: 12, color: color),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  const _RecentSessionCard({
    required this.session,
    this.onEdit,
    this.onDelete,
    required this.durationLabel,
    required this.startLabel,
    this.pauseLabel,
  });

  final TimerSession session;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String durationLabel;
  final String startLabel;
  final String? pauseLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: null, // Plus de clic direct
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.timer_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        durationLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Début: $startLabel',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (!session.isRunning)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Fin: ${_formatEndDate(session.endedAt ?? session.startedAt)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      if (pauseLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.pause_circle_filled, color: theme.colorScheme.secondary, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Pause: $pauseLabel',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (session.category != null || (session.label != null && session.label!.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              if (session.category != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(session.category!.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(int.parse(session.category!.color.substring(1), radix: 16) + 0xFF000000).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(session.category!.color.substring(1), radix: 16) + 0xFF000000),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        session.category!.name,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(int.parse(session.category!.color.substring(1), radix: 16) + 0xFF000000),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (session.label != null && session.label!.isNotEmpty) const SizedBox(width: 6),
                              ],
                              if (session.label != null && session.label!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    session.label!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 24,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatEndDate(DateTime endedAt) {
    return '${endedAt.day.toString().padLeft(2, '0')}/${endedAt.month.toString().padLeft(2, '0')} ${endedAt.hour.toString().padLeft(2, '0')}:${endedAt.minute.toString().padLeft(2, '0')}';
  }
}
