import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/task.dart';
import '../../../models/tag.dart';
import '../../../models/goal.dart';
import '../../../models/enums.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/dropdown.dart';
import '../../../widgets/date_picker.dart';
import '../../../widgets/dialog.dart';

/// 添加任务对话框 - 紧凑专业设计版本
class AddTaskDialog extends StatefulWidget {
  final List<Tag> availableTags;
  final List<Goal> availableGoals;
  final String? parentTaskId;
  final String? defaultGoalId;

  const AddTaskDialog({
    super.key,
    this.availableTags = const [],
    this.availableGoals = const [],
    this.parentTaskId,
    this.defaultGoalId,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  String? _selectedGoalId;
  final Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    _selectedGoalId = widget.defaultGoalId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  void _submit() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final selectedTags = widget.availableTags
          .where((tag) => _selectedTagIds.contains(tag.id))
          .toList();

      final task = Task(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _dueDate,
        parentTaskId: widget.parentTaskId,
        goalId: _selectedGoalId,
        priority: _priority,
        status: TaskStatus.pending,
        tags: selectedTags,
        createdAt: now,
        updatedAt: now,
      );
      Navigator.of(context).pop(task);
    }
  }

  Color _parseColor(String hexColor) {
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isSubtask = widget.parentTaskId != null;

    return DialogBox(
      title: isSubtask ? 'Add New Subtask' : 'Add New Task',
      onClose: () => Navigator.pop(context),
      width: 480,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            AppTextField(
              label: 'Task Title',
              hint: 'e.g., Design homepage mockup',
              helper: 'Make it clear and actionable',
              controller: _titleController,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Task title is required';
                }
                if (value.trim().length > 200) {
                  return 'Task title must be less than 200 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18), // 18px

            // Description
            AppTextField(
              label: 'Description (optional)',
              hint: 'Add more details...',
              helper: 'Help your team understand the context',
              controller: _descriptionController,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value != null && value.length > 1000) {
                  return 'Description must be less than 1000 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 18), // 18px

            // Goal Selection (Only for top-level tasks)
            if (!isSubtask && widget.availableGoals.isNotEmpty) ...[
              ProfessionalDropdown<String>(
                label: 'Associated Goal (optional)',
                helper: 'Link this task to a goal',
                value: _selectedGoalId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No goal - Miscellaneous task'),
                  ),
                  ...widget.availableGoals.map((goal) => DropdownMenuItem(
                    value: goal.id,
                    child: Text(goal.name),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedGoalId = value),
              ),
              const SizedBox(height: 18), // 18px
            ],

            // Due Date
            DatePicker(
              label: 'Due Date (optional)',
              helper: 'When should this be completed?',
              selectedDate: _dueDate,
              formatDate: _formatDate,
              onDateChanged: (date) => setState(() => _dueDate = date),
              onClear: () => setState(() => _dueDate = null),
            ),
            const SizedBox(height: 18), // 18px

            // Priority Level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSm,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8), // 8px
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _PriorityButton(
                        label: 'Low',
                        icon: Icons.arrow_downward,
                        isSelected: _priority == TaskPriority.low,
                        color: const Color(0xFF10B981),
                        onTap: () =>
                            setState(() => _priority = TaskPriority.low),
                      ),
                      const SizedBox(width: 6), // 缩小 30%
                      _PriorityButton(
                        label: 'Medium',
                        icon: Icons.remove,
                        isSelected: _priority == TaskPriority.medium,
                        color: const Color(0xFFF59E0B),
                        onTap: () =>
                            setState(() => _priority = TaskPriority.medium),
                      ),
                      const SizedBox(width: 6), // 缩小 30%
                      _PriorityButton(
                        label: 'High',
                        icon: Icons.arrow_upward,
                        isSelected: _priority == TaskPriority.high,
                        color: const Color(0xFFEF4444),
                        onTap: () =>
                            setState(() => _priority = TaskPriority.high),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Tags
            if (widget.availableTags.isNotEmpty) ...[
              const SizedBox(height: 18), // 18px
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSm,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8), // 8px
                  Wrap(
                    spacing: 8, // 8px
                    runSpacing: 8, // 8px
                    children: widget.availableTags.map((tag) {
                      final isSelected = _selectedTagIds.contains(tag.id);
                      final tagColor = _parseColor(tag.color);
                      return _TagChip(
                        label: tag.name,
                        color: tagColor,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTagIds.remove(tag.id);
                            } else {
                              _selectedTagIds.add(tag.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        DialogButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        DialogButton(
          label: isSubtask ? 'Create Subtask' : 'Create Task',
          onPressed: _submit,
          isPrimary: true,
        ),
      ],
    );
  }
}

/// Priority Button Component - 优先级按钮
class _PriorityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9, // 缩小 30%
          vertical: 5, // 缩小 30%
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected ? color.withAlpha(12) : AppTheme.backgroundColor,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(8),
                    blurRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10, // 缩小 30%
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4), // 缩小 30%
            Text(
              label,
              style: TextStyle(
                fontSize: 9, // 缩小 30%
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tag Chip Component - 标签芯片
class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, // 12px
          vertical: 7, // 7px
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? color : AppTheme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected ? color.withAlpha(12) : AppTheme.backgroundColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check,
                  size: 13,
                  color: color,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 显示添加任务对话框
Future<Task?> showAddTaskDialog(
  BuildContext context, {
  List<Tag> availableTags = const [],
  List<Goal> availableGoals = const [],
  String? parentTaskId,
  String? defaultGoalId,
}) {
  return showDialog<Task>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddTaskDialog(
      availableTags: availableTags,
      availableGoals: availableGoals,
      parentTaskId: parentTaskId,
      defaultGoalId: defaultGoalId,
    ),
  );
}
