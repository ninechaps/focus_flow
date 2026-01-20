import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/task.dart';
import '../../../models/tag.dart';
import '../../../models/goal.dart';
import '../../../models/enums.dart';
import '../../../theme/app_theme.dart';

/// Dialog for adding a new task
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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      setState(() {
        _dueDate = DateTime(date.year, date.month, date.day);
      });
    }
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isSubtask = widget.parentTaskId != null;

    return AlertDialog(
      title: Text(
        isSubtask ? 'Add Subtask' : 'Add Task',
        style: const TextStyle(fontSize: AppTheme.fontSizeLg, fontWeight: FontWeight.w600),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(fontSize: AppTheme.fontSizeSm),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
                    hintText: 'Enter task title',
                    hintStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: AppTheme.fontSizeXs),
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
                    hintText: 'Enter task description',
                    hintStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Goal selection (only for top-level tasks)
                if (!isSubtask && widget.availableGoals.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGoalId,
                    decoration: InputDecoration(
                      labelText: 'Goal (optional)',
                      labelStyle: TextStyle(fontSize: AppTheme.fontSizeXs),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                    style: TextStyle(fontSize: AppTheme.fontSizeSm, color: AppTheme.textPrimary),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No goal (miscellaneous)'),
                      ),
                      ...widget.availableGoals.map((goal) => DropdownMenuItem(
                        value: goal.id,
                        child: Text(goal.name),
                      )),
                    ],
                    onChanged: (value) => setState(() => _selectedGoalId = value),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                ],

                // Due Date
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _dueDate != null
                                ? _formatDate(_dueDate!)
                                : 'Select due date (optional)',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXs,
                              color: _dueDate != null
                                  ? AppTheme.textPrimary
                                  : AppTheme.textHint,
                            ),
                          ),
                        ),
                        if (_dueDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _dueDate = null),
                            child: Icon(Icons.clear, size: 14, color: AppTheme.textHint),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Priority
                Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXs,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                SegmentedButton<TaskPriority>(
                  style: ButtonStyle(
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: AppTheme.fontSizeXs)),
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: TaskPriority.low,
                      label: Text('Low'),
                      icon: Icon(Icons.arrow_downward, size: 12),
                    ),
                    ButtonSegment(
                      value: TaskPriority.medium,
                      label: Text('Med'),
                      icon: Icon(Icons.remove, size: 12),
                    ),
                    ButtonSegment(
                      value: TaskPriority.high,
                      label: Text('High'),
                      icon: Icon(Icons.arrow_upward, size: 12),
                    ),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selected) {
                    setState(() => _priority = selected.first);
                  },
                ),
                const SizedBox(height: AppTheme.spacingSm),

                // Tags
                if (widget.availableTags.isNotEmpty) ...[
                  Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeXs,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.availableTags.map((tag) {
                      final isSelected = _selectedTagIds.contains(tag.id);
                      final tagColor = _parseColor(tag.color);
                      return FilterChip(
                        label: Text(tag.name, style: TextStyle(fontSize: AppTheme.fontSizeXs)),
                        selected: isSelected,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTagIds.add(tag.id);
                            } else {
                              _selectedTagIds.remove(tag.id);
                            }
                          });
                        },
                        selectedColor: tagColor.withValues(alpha: 0.15),
                        checkmarkColor: tagColor,
                        labelStyle: TextStyle(
                          fontSize: AppTheme.fontSizeXs,
                          color: isSelected ? tagColor : AppTheme.textPrimary,
                        ),
                        side: BorderSide(
                          color: isSelected ? tagColor : AppTheme.dividerColor,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
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

/// Show add task dialog and return the created task
Future<Task?> showAddTaskDialog(
  BuildContext context, {
  List<Tag> availableTags = const [],
  List<Goal> availableGoals = const [],
  String? parentTaskId,
  String? defaultGoalId,
}) {
  return showDialog<Task>(
    context: context,
    builder: (context) => AddTaskDialog(
      availableTags: availableTags,
      availableGoals: availableGoals,
      parentTaskId: parentTaskId,
      defaultGoalId: defaultGoalId,
    ),
  );
}
