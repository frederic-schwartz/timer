import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

class CategoryEditDialog extends StatefulWidget {
  const CategoryEditDialog({
    super.key,
    this.category,
  });

  final Category? category;

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late final TextEditingController _nameController;
  String _selectedColor = '#2196F3';

  final List<String> _predefinedColors = [
    '#2196F3', // Bleu
    '#4CAF50', // Vert
    '#FF5722', // Rouge orangé
    '#FF9800', // Orange
    '#9C27B0', // Violet
    '#3F51B5', // Indigo
    '#00BCD4', // Cyan
    '#8BC34A', // Vert clair
    '#FFC107', // Ambre
    '#E91E63', // Rose
    '#795548', // Marron
    '#607D8B', // Bleu gris
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? '#2196F3';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la catégorie',
                border: OutlineInputBorder(),
              ),
              autofocus: !isEditing,
            ),
            const SizedBox(height: 20),
            Text(
              'Couleur',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _predefinedColors.map((color) => GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _selectedColor == color
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.of(context).pop({
                    'name': _nameController.text.trim(),
                    'color': _selectedColor,
                  });
                },
          child: Text(isEditing ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }
}