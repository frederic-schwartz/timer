import 'package:flutter/material.dart';

import '../../domain/entities/timer_session.dart';
import '../../domain/entities/category.dart' as entities;
import '../controllers/sessions_controller.dart';
import '../widgets/session_card.dart';
import 'edit_session_screen.dart';

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


  Future<void> _editSession(TimerSession session) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSessionScreen(session: session),
      ),
    );

    if (result == true) {
      // Session modifiée, recharger les données
      _controller.loadSessions();
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Historique des sessions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vos sessions terminées',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showFilterDialog(context),
                            icon: Icon(
                              Icons.filter_list,
                              color: (_controller.startDate != null ||
                                     _controller.endDate != null ||
                                     _controller.selectedCategory != null)
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      if (_controller.startDate != null ||
                          _controller.endDate != null ||
                          _controller.selectedCategory != null)
                        _buildActiveFilters(theme),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          '${_controller.resultsCount} résultat${_controller.resultsCount > 1 ? 's' : ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _controller.loadSessions,
                          child: sessions.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height * 0.4,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.timer_off_rounded,
                                            size: 72,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Aucune session terminée',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: sessions.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final session = sessions[index];

                                    return SessionCard(
                                      session: session,
                                      onEdit: () => _editSession(session),
                                      onDelete: () => _deleteSession(session),
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
    );
  }

  Widget _buildActiveFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_controller.startDate != null || _controller.endDate != null)
            Chip(
              label: Text(_getDateRangeText()),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _controller.setDateRange(null, null),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          if (_controller.selectedCategory != null)
            Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(int.parse(_controller.selectedCategory!.color.substring(1), radix: 16) + 0xFF000000),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_controller.selectedCategory!.name),
                ],
              ),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => _controller.setCategory(null),
              backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
            ),
          TextButton.icon(
            onPressed: _controller.clearFilters,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Effacer tout'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeText() {
    if (_controller.startDate != null && _controller.endDate != null) {
      return '${_formatDate(_controller.startDate!)} - ${_formatDate(_controller.endDate!)}';
    } else if (_controller.startDate != null) {
      return 'Depuis ${_formatDate(_controller.startDate!)}';
    } else if (_controller.endDate != null) {
      return 'Jusqu\'au ${_formatDate(_controller.endDate!)}';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(controller: _controller),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final SessionsController controller;

  const _FilterDialog({required this.controller});

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  entities.Category? _tempSelectedCategory;

  @override
  void initState() {
    super.initState();
    _tempStartDate = widget.controller.startDate;
    _tempEndDate = widget.controller.endDate;
    _tempSelectedCategory = widget.controller.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Filtrer les sessions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectStartDate(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_tempStartDate != null
                        ? _formatDate(_tempStartDate!)
                        : 'Date début'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectEndDate(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_tempEndDate != null
                        ? _formatDate(_tempEndDate!)
                        : 'Date fin'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Catégorie',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<entities.Category?>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              initialValue: _tempSelectedCategory,
              items: [
                const DropdownMenuItem<entities.Category?>(
                  value: null,
                  child: Text('Toutes les catégories'),
                ),
                ...widget.controller.categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _tempSelectedCategory = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            widget.controller.setDateRange(_tempStartDate, _tempEndDate);
            widget.controller.setCategory(_tempSelectedCategory);
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tempStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _tempStartDate = date;
      });
    }
  }

  void _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tempEndDate ?? DateTime.now(),
      firstDate: _tempStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _tempEndDate = date;
      });
    }
  }
}
