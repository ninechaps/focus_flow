import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/task.dart';
import '../../../models/tag.dart';
import '../../../models/goal.dart';
import '../../../models/enums.dart';
import '../../../providers/user_preferences_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/dropdown.dart';
import '../../../widgets/date_picker.dart';
import '../../../widgets/dialog.dart';

/// 添加/编辑任务对话框 - macOS 风格精致设计
class AddTaskDialog extends StatefulWidget {
  final List<Tag> availableTags;
  final List<Goal> availableGoals;
  final String? parentTaskId;
  final String? defaultGoalId;
  /// 默认截止日期（用于从日程页快速创建任务）
  final DateTime? defaultDueDate;
  /// 传入时为编辑模式
  final Task? editTask;

  const AddTaskDialog({
    super.key,
    this.availableTags = const [],
    this.availableGoals = const [],
    this.parentTaskId,
    this.defaultGoalId,
    this.defaultDueDate,
    this.editTask,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium; // overridden in initState
  DateTime? _dueDate;
  String? _selectedGoalId;
  final Set<String> _selectedTagIds = {};

  bool get _isEditing => widget.editTask != null;
  bool get _isSubtask => widget.parentTaskId != null || widget.editTask?.parentTaskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final task = widget.editTask!;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _priority = task.priority;
      _dueDate = task.dueDate;
      _selectedGoalId = task.goalId;
      _selectedTagIds.addAll(task.tags.map((t) => t.id));
    } else {
      _selectedGoalId = widget.defaultGoalId;
      _dueDate = widget.defaultDueDate;
      // Apply user's default priority preference for new tasks
      final defaultPriority = context.read<UserPreferencesProvider>().defaultPriority;
      if (defaultPriority != null) {
        _priority = defaultPriority;
      }
    }
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
        id: _isEditing ? widget.editTask!.id : const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _dueDate,
        parentTaskId: _isEditing ? widget.editTask!.parentTaskId : widget.parentTaskId,
        goalId: _selectedGoalId,
        priority: _priority,
        status: _isEditing ? widget.editTask!.status : TaskStatus.pending,
        tags: selectedTags,
        focusDuration: _isEditing ? widget.editTask!.focusDuration : 0,
        sortOrder: _isEditing ? widget.editTask!.sortOrder : 0,
        completedAt: _isEditing ? widget.editTask!.completedAt : null,
        createdAt: _isEditing ? widget.editTask!.createdAt : now,
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
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    final dialogTitle = _isEditing
        ? (_isSubtask ? l10n.editSubtask : l10n.editTask)
        : (_isSubtask ? l10n.newSubtask : l10n.newTask);
    final submitLabel = _isEditing ? l10n.save : (_isSubtask ? l10n.createSubtask : l10n.createTask);

    return DialogBox(
      title: dialogTitle,
      onClose: () => Navigator.pop(context),
      width: 520,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务标题
            AppTextField(
              label: l10n.taskTitle,
              hint: l10n.taskTitlePlaceholder,
              controller: _titleController,
              autofocus: !_isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.taskTitleRequired;
                }
                if (value.trim().length > 200) {
                  return l10n.taskTitleTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // 描述
            AppTextField(
              label: l10n.descriptionOptional,
              hint: l10n.descriptionPlaceholder,
              controller: _descriptionController,
              maxLines: 2,
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value != null && value.length > 1000) {
                  return l10n.descriptionTooLong;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // 优先级 + 截止日期 同一行
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 优先级
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.priority,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSm,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _PriorityDot(
                            label: l10n.priorityLowShort,
                            color: AppTheme.successColor,
                            isSelected: _priority == TaskPriority.low,
                            onTap: () => setState(() => _priority = TaskPriority.low),
                          ),
                          const SizedBox(width: 8),
                          _PriorityDot(
                            label: l10n.priorityMediumShort,
                            color: const Color(0xFFF59E0B),
                            isSelected: _priority == TaskPriority.medium,
                            onTap: () => setState(() => _priority = TaskPriority.medium),
                          ),
                          const SizedBox(width: 8),
                          _PriorityDot(
                            label: l10n.priorityHighShort,
                            color: AppTheme.errorColor,
                            isSelected: _priority == TaskPriority.high,
                            onTap: () => setState(() => _priority = TaskPriority.high),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 截止日期
                Expanded(
                  child: DatePicker(
                    label: l10n.dueDateOptional,
                    selectedDate: _dueDate,
                    formatDate: _formatDate,
                    onDateChanged: (date) => setState(() => _dueDate = date),
                    onClear: () => setState(() => _dueDate = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 关联目标 + 标签 同一行（或按需展示）
            if (!_isSubtask && widget.availableGoals.isNotEmpty) ...[
              ProfessionalDropdown<String>(
                label: l10n.relatedGoalOptional,
                value: _selectedGoalId,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(l10n.noRelatedGoal),
                  ),
                  ...widget.availableGoals.map((goal) => DropdownMenuItem(
                    value: goal.id,
                    child: Text(goal.name),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedGoalId = value),
              ),
              const SizedBox(height: 14),
            ],

            // 标签
            if (widget.availableTags.isNotEmpty) ...[
              Text(
                l10n.tags,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSm,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
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
          ],
        ),
      ),
      actions: [
        DialogButton(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        DialogButton(
          label: submitLabel,
          onPressed: _submit,
          isPrimary: true,
        ),
      ],
    );
  }
}

/// 优先级圆点选择器 — Things 3 风格
class _PriorityDot extends StatefulWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityDot({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PriorityDot> createState() => _PriorityDotState();
}

class _PriorityDotState extends State<_PriorityDot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.12)
                : _isHovered
                    ? colors.hoverBg
                    : Colors.transparent,
            border: Border.all(
              color: widget.isSelected ? widget.color : colors.divider,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: widget.isSelected
                      ? [BoxShadow(color: widget.color.withValues(alpha: 0.4), blurRadius: 4)]
                      : null,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isSelected ? widget.color : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 标签选择芯片
class _TagChip extends StatefulWidget {
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
  State<_TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<_TagChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.1)
                : _isHovered
                    ? colors.hoverBg
                    : colors.badgeBg,
            border: Border.all(
              color: widget.isSelected ? widget.color : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: widget.isSelected ? widget.color : colors.textPrimary,
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check, size: 11, color: widget.color),
              ],
            ],
          ),
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
  DateTime? defaultDueDate,
}) {
  return showDialog<Task>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddTaskDialog(
      availableTags: availableTags,
      availableGoals: availableGoals,
      parentTaskId: parentTaskId,
      defaultGoalId: defaultGoalId,
      defaultDueDate: defaultDueDate,
    ),
  );
}

/// 显示编辑任务对话框
Future<Task?> showEditTaskDialog(
  BuildContext context, {
  required Task task,
  List<Tag> availableTags = const [],
  List<Goal> availableGoals = const [],
}) {
  return showDialog<Task>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AddTaskDialog(
      availableTags: availableTags,
      availableGoals: availableGoals,
      editTask: task,
    ),
  );
}
