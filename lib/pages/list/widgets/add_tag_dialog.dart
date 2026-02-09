import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/tag.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/dialog.dart';

/// 添加标签对话框 - 紧凑专业设计版本
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
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;

    return DialogBox(
      title: l10n.createNewTag,
      onClose: () => Navigator.pop(context),
      width: 420,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tag Name
            AppTextField(
              label: l10n.tagName,
              hint: l10n.tagNamePlaceholder,
              helper: l10n.tagNameHint,
              controller: _nameController,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.tagNameRequired;
                }
                if (value.trim().length > 50) {
                  return l10n.tagNameTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 18), // 18px

            // Color Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.selectColor,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSm,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8), // 8px
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((color) {
                    final isSelected = _selectedColor == color;
                    final colorValue = _parseColor(color);
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorValue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : colorValue.withAlpha(128),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colorValue.withAlpha(80),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      blurRadius: 4,
                                    ),
                                  ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        DialogButton(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        DialogButton(
          label: l10n.createTag,
          onPressed: _submit,
          isPrimary: true,
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
