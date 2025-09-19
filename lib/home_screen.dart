import 'package:flutter/material.dart';
import 'dart:async';
import 'services/timer_service.dart';

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
      });
    });

    _stateSubscription = _timerService.stateStream.listen((state) {
      setState(() {
        _currentState = state;
      });
    });

    setState(() {
      _currentDuration = _timerService.currentDuration;
      _currentState = _timerService.currentState;
    });
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
}