import 'package:flutter/material.dart';

import '../../domain/entities/timer_session.dart';
import '../../domain/entities/timer_state.dart';
import '../controllers/home_controller.dart';
import 'about_screen.dart';
import 'sessions_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
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

  Future<void> _startTimer() async {
    await _controller.startTimer();
  }

  Future<void> _pauseTimer() async {
    await _controller.pauseTimer();
  }

  Future<void> _stopTimer() async {
    await _controller.stopTimer();
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
    final pauseLabel = _controller.totalPauseRealTime.inSeconds > 0
        ? _formatDuration(_controller.totalPauseRealTime)
        : '—';

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
          _StateBadge(label: _stateLabel(state), color: accent),
          const SizedBox(height: 24),
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
          const SizedBox(height: 12),
          Row(
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
                ),
              ),
              if (state == TimerState.paused) ...[
                const SizedBox(width: 8),
                Text(
                  '(+${_formatDuration(_controller.currentPauseDuration)})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, TimerState state) {
    final theme = Theme.of(context);
    final isRunning = state == TimerState.running;
    final isPaused = state == TimerState.paused;
    final primaryLabel = isRunning
        ? 'Pause'
        : isPaused
            ? 'Reprendre'
            : 'Démarrer';

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isRunning ? _pauseTimer : _startTimer,
            icon: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 26),
            label: Text(primaryLabel),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              backgroundColor: _stateColor(state, theme),
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton.icon(
            onPressed: state != TimerState.stopped && state != TimerState.ready ? _stopTimer : null,
            icon: const Icon(Icons.stop_rounded, size: 26),
            label: const Text('Stop'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == sessions.length - 1 ? 0 : 12),
            child: _RecentSessionCard(
              session: session,
              onResume: () => _controller.resumeSession(session),
              durationLabel: _formatDuration(session.currentDuration),
              startLabel: _formatDateTime(session.startTime),
              pauseLabel: session.totalPausedDuration > 0
                  ? _formatDuration(Duration(milliseconds: session.totalPausedDuration))
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
    required this.onResume,
    required this.durationLabel,
    required this.startLabel,
    this.pauseLabel,
  });

  final TimerSession session;
  final VoidCallback onResume;
  final String durationLabel;
  final String startLabel;
  final String? pauseLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onResume,
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
                      if (session.endTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Fin: ${_formatEndDate(session.endTime!)}',
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
                    ],
                  ),
                ),
                Icon(
                  Icons.play_arrow_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatEndDate(DateTime endTime) {
    return '${endTime.day.toString().padLeft(2, '0')}/${endTime.month.toString().padLeft(2, '0')} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }
}
