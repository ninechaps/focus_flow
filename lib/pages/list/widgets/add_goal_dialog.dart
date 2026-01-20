import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/goal.dart';
import '../../../theme/app_theme.dart';

/// Dialog for adding a new goal
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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a due date'),
            backgroundColor: Colors.red,
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add Goal',
        style: TextStyle(fontSize: AppTheme.fontSizeLg, fontWeight: FontWeight.w600),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(fontSize: AppTheme.fontSizeSm),
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  labelStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
                  hintText: 'Enter goal name',
                  hintStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // Due Date
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dividerColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? _formatDate(_dueDate!)
                              : 'Select goal due date',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSm,
                            color: _dueDate != null
                                ? AppTheme.textPrimary
                                : AppTheme.textHint,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: Icon(Icons.clear, size: 16, color: AppTheme.textHint),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            textStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            textStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Show add goal dialog and return the created goal
Future<Goal?> showAddGoalDialog(BuildContext context) {
  return showDialog<Goal>(
    context: context,
    builder: (context) => const AddGoalDialog(),
  );
}
