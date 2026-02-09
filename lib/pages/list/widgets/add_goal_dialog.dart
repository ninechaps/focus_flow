import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/goal.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/date_picker.dart';
import '../../../widgets/dialog.dart';

/// 添加目标对话框 - 紧凑专业设计版本
class AddGoalDialog extends StatefulWidget {
  const AddGoalDialog({super.key});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _dueDate;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_dueDate == null) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseSelectDueDate),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final now = DateTime.now();
      final goal = Goal(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        dueDate: _dueDate!,
        createdAt: now,
        updatedAt: now,
      );
      Navigator.of(context).pop(goal);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DialogBox(
      title: l10n.createNewGoal,
      onClose: () => Navigator.pop(context),
      width: 440,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: l10n.goalName,
              hint: l10n.goalNamePlaceholder,
              controller: _nameController,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.goalNameRequired;
                }
                if (value.trim().length > 100) {
                  return l10n.goalNameTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 18), // 18px - 合理的字段间距
            DatePicker(
              label: l10n.targetDueDate,
              helper: l10n.targetDueDateHint,
              selectedDate: _dueDate,
              formatDate: _formatDate,
              onDateChanged: (date) => setState(() => _dueDate = date),
              onClear: () => setState(() => _dueDate = null),
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
          label: l10n.createGoal,
          onPressed: _submit,
          isPrimary: true,
        ),
      ],
    );
  }
}

/// 显示添加目标对话框
Future<Goal?> showAddGoalDialog(BuildContext context) {
  return showDialog<Goal>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AddGoalDialog(),
  );
}
