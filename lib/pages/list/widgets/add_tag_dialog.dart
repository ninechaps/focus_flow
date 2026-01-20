import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/tag.dart';
import '../../../theme/app_theme.dart';

/// Dialog for adding a new tag
class AddTagDialog extends StatefulWidget {
  const AddTagDialog({super.key});

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '6366F1'; // Default purple color

  // Predefined color options
  static const List<String> _colorOptions = [
    '6366F1', // Purple
    '22C55E', // Green
    'F59E0B', // Orange
    'EC4899', // Pink
    '14B8A6', // Teal
    'EF4444', // Red
    '3B82F6', // Blue
    '8B5CF6', // Violet
    'F97316', // Orange
    '06B6D4', // Cyan
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final tag = Tag(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        color: _selectedColor,
        createdAt: now,
        updatedAt: now,
      );
      Navigator.of(context).pop(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Tag'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                hintText: 'Enter tag name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a tag name';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'Select Color',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSm,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _parseColor(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _parseColor(color).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Show add tag dialog and return the created tag
Future<Tag?> showAddTagDialog(BuildContext context) {
  return showDialog<Tag>(
    context: context,
    builder: (context) => const AddTagDialog(),
  );
}
