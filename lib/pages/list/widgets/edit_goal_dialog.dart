import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/goal.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/date_picker.dart';
import '../../../widgets/dialog.dart';

/// 编辑目标对话框 - 紧凑专业设计版本
class EditGoalDialog extends StatefulWidget {
  final Goal goal;

  const EditGoalDialog({
    super.key,
    required this.goal,
  });

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  late final TextEditingController _nameController;
  late DateTime _dueDate;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.goal.name);
    _dueDate = widget.goal.dueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedGoal = widget.goal.copyWith(
        name: _nameController.text.trim(),
        dueDate: _dueDate,
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(updatedGoal);
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
      title: l10n.editGoal,
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
            const SizedBox(height: 18),
            DatePicker(
              label: l10n.targetDueDate,
              helper: l10n.targetDueDateHint,
              selectedDate: _dueDate,
              formatDate: _formatDate,
              onDateChanged: (date) {
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
              onClear: () {
                // Reset to original goal's due date
                setState(() => _dueDate = widget.goal.dueDate);
              },
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
          label: l10n.saveGoal,
          onPressed: _submit,
          isPrimary: true,
        ),
      ],
    );
  }
}

/// 显示编辑目标对话框
Future<Goal?> showEditGoalDialog(BuildContext context, Goal goal) {
  return showDialog<Goal>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EditGoalDialog(goal: goal),
  );
}
