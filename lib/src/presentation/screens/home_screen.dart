import 'package:flutter/material.dart';

import '../../domain/entities/timer_session.dart';
import '../../domain/entities/timer_state.dart';
import '../controllers/home_controller.dart';
import 'about_screen.dart';
import 'all_logs_screen.dart';
import 'session_logs_screen.dart';
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

  Color _getTimerColor(TimerState state) {
    switch (state) {
      case TimerState.running:
        return Colors.green;
      case TimerState.paused:
        return Colors.orange;
      case TimerState.stopped:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
      case TimerState.ready:
        return Colors.blue;
    }
  }

  String _getStateText(TimerState state) {
    switch (state) {
      case TimerState.running:
        return 'En cours...';
      case TimerState.paused:
        return 'En pause';
      case TimerState.stopped:
        return 'Arrêté';
      case TimerState.ready:
        return 'Prêt';
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

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildPauseInfo(TimerState state) {
    if (state == TimerState.stopped) {
      return const SizedBox.shrink();
    }

    final totalPauseRealTime = _controller.totalPauseRealTime;

    if (totalPauseRealTime.inSeconds > 0) {
      return Text(
        'Temps de pause total: ${_formatDuration(totalPauseRealTime)}',
        style: TextStyle(
          fontSize: 14,
          color: state == TimerState.paused
              ? Colors.orange
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: state == TimerState.paused ? FontWeight.w500 : FontWeight.normal,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRecentSessions(List<TimerSession> sessions) {
    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'Sessions récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: InkWell(
                    onTap: () => _controller.resumeSession(session),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.timer,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDuration(session.currentDuration),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(session.startTime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                if (session.totalPausedDuration > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pause: ${_formatDuration(Duration(milliseconds: session.totalPausedDuration))}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SessionLogsScreen(session: session),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.list_alt),
                                tooltip: 'Voir les logs',
                              ),
                              Icon(
                                Icons.play_arrow,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
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
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Timer App',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
            leading: const Icon(Icons.list_alt),
            title: const Text('Logs'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllLogsScreen(),
                ),
              );
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
            leading: const Icon(Icons.info),
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

  @override
  Widget build(BuildContext context) {
    final state = _controller.currentState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: _buildDrawer(),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _formatDuration(_controller.currentDuration),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _getTimerColor(state),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: state == TimerState.running ? Icons.pause : Icons.play_arrow,
                            label: state == TimerState.running ? 'Pause' : 'Start',
                            color: state == TimerState.running ? Colors.orange : Colors.green,
                            onPressed: state == TimerState.running ? _pauseTimer : _startTimer,
                          ),
                          _buildControlButton(
                            icon: Icons.stop,
                            label: 'Stop',
                            color: Colors.red,
                            onPressed: state != TimerState.stopped && state != TimerState.ready ? _stopTimer : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _getStateText(state),
                        style: TextStyle(
                          fontSize: 18,
                          color: _getTimerColor(state),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPauseInfo(state),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildRecentSessions(_controller.recentSessions),
                ),
              ],
            ),
    );
  }
}
