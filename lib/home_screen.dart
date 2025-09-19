import 'package:flutter/material.dart';
import 'dart:async';
import 'services/timer_service.dart';
import 'services/database_service.dart';
import 'models/timer_session.dart';
import 'sessions_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TimerService _timerService = TimerService();
  Duration _currentDuration = Duration.zero;
  TimerState _currentState = TimerState.stopped;
  late StreamSubscription _durationSubscription;
  late StreamSubscription _stateSubscription;
  List<TimerSession> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  Future<void> _initializeTimer() async {
    await _timerService.initialize();

    _durationSubscription = _timerService.durationStream.listen((duration) {
      setState(() {
        _currentDuration = duration;
        // Force UI refresh to update pause durations
      });
    });

    _stateSubscription = _timerService.stateStream.listen((state) {
      setState(() {
        _currentState = state;
      });
      if (state == TimerState.stopped) {
        _loadRecentSessions();
      }
    });

    setState(() {
      _currentDuration = _timerService.currentDuration;
      _currentState = _timerService.currentState;
    });

    await _loadRecentSessions();
  }

  Future<void> _loadRecentSessions() async {
    try {
      final sessions = await DatabaseService.getAllSessions();
      setState(() {
        _recentSessions = sessions
            .where((session) => !session.isRunning)
            .take(3)
            .toList();
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _durationSubscription.cancel();
    _stateSubscription.cancel();
    _timerService.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: _buildDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                _formatDuration(_currentDuration),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getTimerColor(),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _currentState == TimerState.running ? Icons.pause : Icons.play_arrow,
                  label: _currentState == TimerState.running ? 'Pause' : 'Start',
                  color: _currentState == TimerState.running ? Colors.orange : Colors.green,
                  onPressed: _currentState == TimerState.running ? _pauseTimer : _startTimer,
                ),
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  color: Colors.red,
                  onPressed: _currentState != TimerState.stopped ? _stopTimer : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _getStateText(),
              style: TextStyle(
                fontSize: 18,
                color: _getTimerColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildPauseInfo(),
            const SizedBox(height: 32),
            _buildRecentSessions(),
          ],
        ),
      ),
    );
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

  Color _getTimerColor() {
    switch (_currentState) {
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

  String _getStateText() {
    switch (_currentState) {
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

  Future<void> _startTimer() async {
    await _timerService.startTimer();
  }

  Future<void> _pauseTimer() async {
    await _timerService.pauseTimer();
  }

  Future<void> _stopTimer() async {
    await _timerService.stopTimer();
  }

  Widget _buildDrawer() {
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
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionsScreen(timerService: _timerService),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Réglages'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
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

  Widget _buildRecentSessions() {
    if (_recentSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Sessions récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSessions.length,
            itemBuilder: (context, index) {
              final session = _recentSessions[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: InkWell(
                    onTap: () => _timerService.resumeSession(session),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(session.currentDuration),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(session.startTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPauseInfo() {
    if (_currentState == TimerState.stopped || _currentState == TimerState.ready) {
      return const SizedBox.shrink();
    }

    final totalPause = _timerService.totalPausedDuration;
    final currentPause = _timerService.currentPauseDuration;

    return Column(
      children: [
        if (totalPause.inSeconds > 0)
          Text(
            'Temps de pause total: ${_formatDuration(totalPause)}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        if (_currentState == TimerState.paused && currentPause.inSeconds > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Pause en cours: ${_formatDuration(currentPause)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}