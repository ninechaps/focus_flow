import 'package:flutter/material.dart';
import '../../../models/tag.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/dialog.dart';

/// 编辑标签对话框 - 紧凑专业设计版本
class EditTagDialog extends StatefulWidget {
  final Tag tag;

  const EditTagDialog({
    super.key,
    required this.tag,
  });

  @override
  State<EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends State<EditTagDialog> {
  late final TextEditingController _nameController;
  late String _selectedColor;
  late final GlobalKey<FormState> _formKey;

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
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.tag.name);
    _selectedColor = widget.tag.color;
  }

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
      final updatedTag = widget.tag.copyWith(
        name: _nameController.text.trim(),
        color: _selectedColor,
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(updatedTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DialogBox(
      title: 'Edit Tag',
      onClose: () => Navigator.pop(context),
      width: 420,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tag Name
            AppTextField(
              label: 'Tag Name',
              hint: 'e.g., Design, Development',
              helper: 'Give your tag a descriptive name',
              controller: _nameController,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tag name is required';
                }
                if (value.trim().length > 50) {
                  return 'Tag name must be less than 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Color Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Color',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSm,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
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
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        DialogButton(
          label: 'Save Tag',
          onPressed: _submit,
          isPrimary: true,
        ),
      ],
    );
  }
}

/// 显示编辑标签对话框
Future<Tag?> showEditTagDialog(BuildContext context, Tag tag) {
  return showDialog<Tag>(
    context: context,
    builder: (context) => EditTagDialog(tag: tag),
  );
}
