import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

class CategorySelectionDialog extends StatefulWidget {
  const CategorySelectionDialog({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.currentLabel,
  });

  final List<Category> categories;
  final Category? selectedCategory;
  final String? currentLabel;

  @override
  State<CategorySelectionDialog> createState() => _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  Category? _selectedCategory;
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _labelController = TextEditingController(text: widget.currentLabel ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Catégorie et libellé'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catégorie',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Option "Aucune"
                _CategoryChip(
                  label: 'Aucune',
                  color: theme.colorScheme.outline,
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                // Catégories disponibles
                ...widget.categories.map((category) => _CategoryChip(
                  label: category.name,
                  color: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000),
                  isSelected: _selectedCategory?.id == category.id,
                  onTap: () => setState(() => _selectedCategory = category),
                )),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Libellé (optionnel)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                hintText: 'Ajouter une note...',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
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
          onPressed: () {
            Navigator.of(context).pop({
              'category': _selectedCategory,
              'label': _labelController.text.trim().isEmpty ? null : _labelController.text.trim(),
            });
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}