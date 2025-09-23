import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/category.dart' as entities;
import '../../domain/entities/timer_session.dart';
import '../../dependency_injection/service_locator.dart';

class EditSessionScreen extends StatefulWidget {
  const EditSessionScreen({super.key, required this.session});

  final TimerSession session;

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _dependencies = AppDependencies.instance;

  late DateTime _startedAt;
  late DateTime? _endedAt;
  late int _totalPauseDuration;
  entities.Category? _selectedCategory;
  late String _label;

  List<entities.Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.session.startedAt;
    _endedAt = widget.session.endedAt;
    _totalPauseDuration = widget.session.totalPauseDuration;
    _label = widget.session.label ?? '';
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _dependencies.getAllCategories();

      // Trouver la catégorie correspondante dans la liste par ID
      if (widget.session.category != null) {
        final sessionCategoryId = widget.session.category!.id;
        _selectedCategory = _categories
            .cast<entities.Category?>()
            .firstWhere(
              (cat) => cat?.id == sessionCategoryId,
              orElse: () => null,
            );
      } else {
        _selectedCategory = null;
      }

      setState(() {});
    } catch (e) {
      // Ignorer les erreurs
      _selectedCategory = null;
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startedAt : (_endedAt ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStart) {
            _startedAt = newDateTime;
            // S'assurer que la fin n'est pas avant le début
            if (_endedAt != null && _endedAt!.isBefore(_startedAt)) {
              _endedAt = _startedAt.add(const Duration(minutes: 1));
            }
          } else {
            _endedAt = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _selectPauseDuration() async {
    final controller = TextEditingController(
      text: (Duration(milliseconds: _totalPauseDuration).inMinutes).toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durée de pause (minutes)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Minutes',
            suffixText: 'min',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context, minutes * 60 * 1000); // Convertir en millisecondes
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _totalPauseDuration = result;
      });
    }
  }

  Future<void> _save() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer une nouvelle session avec les modifications
      final updatedSession = TimerSession(
        id: widget.session.id,
        startedAt: _startedAt,
        endedAt: _endedAt,
        totalPauseDuration: _totalPauseDuration,
        isPaused: widget.session.isPaused,
        category: _selectedCategory,
        label: _label.isEmpty ? null : _label,
      );

      // Utiliser le use case updateSession pour toutes les sessions
      await _dependencies.updateSession(updatedSession);

      if (mounted) {
        Navigator.pop(context, true); // Retourner true pour indiquer que la session a été modifiée
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la session'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sauvegarder'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Horaires',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: const Text('Début'),
                    subtitle: Text(_formatDateTime(_startedAt)),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _selectDateTime(context, true),
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.stop),
                    title: const Text('Fin'),
                    subtitle: Text(_endedAt != null ? _formatDateTime(_endedAt!) : 'En cours...'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _selectDateTime(context, false),
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.pause),
                    title: const Text('Durée de pause'),
                    subtitle: Text(_formatDuration(Duration(milliseconds: _totalPauseDuration))),
                    trailing: const Icon(Icons.edit),
                    onTap: _selectPauseDuration,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<entities.Category?>(
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    items: [
                      const DropdownMenuItem<entities.Category?>(
                        value: null,
                        child: Text('Aucune catégorie'),
                      ),
                      ..._categories.map((category) => DropdownMenuItem(
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
                        _selectedCategory = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Libellé',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _label,
                    onChanged: (value) {
                      _label = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}