import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/enums.dart';
import '../../providers/task_provider.dart';
import 'widgets/task_list_panel.dart';
import 'widgets/tips_panel.dart';
import 'widgets/add_task_dialog.dart';

/// List page - Main task list view with two-panel layout
/// Left: Task list grouped by time
/// Right: Detail panel (tips/task details)
class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  String? _selectedTaskId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TaskProvider>();
      if (provider.tasks.isEmpty && !provider.isLoading) {
        provider.init();
      }
    });
  }

  void _handleTaskTap(Task task) {
    setState(() {
      _selectedTaskId = task.id;
    });
  }

  void _handleFocus(Task task) {
    context.go('/app/focus/${task.id}');
  }

  Future<void> _handleAddSubtask(Task parentTask) async {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final task = await showAddTaskDialog(
      context,
      availableTags: provider.tags,
      availableGoals: provider.goals,
      parentTaskId: parentTask.id,
    );

    if (task != null && mounted) {
      try {
        await provider.addTask(task);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('子任务已创建'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('创建子任务失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleAddTask() async {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final task = await showAddTaskDialog(
      context,
      availableTags: provider.tags,
      availableGoals: provider.goals,
      defaultGoalId: provider.selectedGoalId,
    );

    if (task != null && mounted) {
      try {
        await provider.addTask(task);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('任务已创建'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('创建任务失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ===== 右键菜单回调 =====

  Future<void> _handleEditTask(Task task) async {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final updatedTask = await showEditTaskDialog(
      context,
      task: task,
      availableTags: provider.tags,
      availableGoals: provider.goals,
    );

    if (updatedTask != null && mounted) {
      try {
        await provider.updateTask(updatedTask);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('任务已更新'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('更新任务失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除「${task.title}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TaskProvider>();
      final messenger = ScaffoldMessenger.of(context);
      try {
        await provider.deleteTask(task.id);
        if (_selectedTaskId == task.id) {
          setState(() => _selectedTaskId = null);
        }
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('任务已删除'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('删除任务失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleSetPriority(Task task, TaskPriority priority) async {
    final provider = context.read<TaskProvider>();
    try {
      final updated = task.copyWith(
        priority: priority,
        updatedAt: DateTime.now(),
      );
      await provider.updateTask(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置优先级失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSetStatus(Task task, TaskStatus status) async {
    final provider = context.read<TaskProvider>();
    try {
      final updated = task.copyWith(
        status: status,
        completedAt: status == TaskStatus.completed ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );
      await provider.updateTask(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置状态失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.init(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final bool showRightPanel = provider.selectedGoalId != null || _selectedTaskId != null;

        return Row(
          children: [
            Expanded(
              child: TaskListPanel(
                tasks: provider.filteredTasks,
                subtasksMap: provider.filteredSubtasksMap,
                searchQuery: provider.searchQuery,
                selectedTaskId: _selectedTaskId,
                selectedStatusFilter: provider.selectedStatusFilter,
                onSearchChanged: provider.setSearchQuery,
                onStatusChanged: provider.setStatusFilter,
                onTaskStatusChanged: (task) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await provider.toggleTaskStatus(task.id);
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                onTaskTap: _handleTaskTap,
                onAddSubtask: _handleAddSubtask,
                onAddTask: _handleAddTask,
                onFocus: _handleFocus,
                onEditTask: _handleEditTask,
                onDeleteTask: _handleDeleteTask,
                onSetPriority: _handleSetPriority,
                onSetStatus: _handleSetStatus,
                onReorder: (groupKey, oldIndex, newIndex, groupTasks) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await provider.reorderTasks(groupKey, oldIndex, newIndex, groupTasks);
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('排序失败: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                onSubtasksReorder: (parentTask, oldIndex, newIndex) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final subtasks = provider.subtasksMap[parentTask.id] ?? [];
                    await provider.reorderTasks('subtasks_${parentTask.id}', oldIndex, newIndex, subtasks);
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('排序失败: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ),

            if (showRightPanel)
              TipsPanel(
                goals: provider.goals,
                tasks: provider.tasks,
                selectedGoalId: provider.selectedGoalId,
                selectedTaskId: _selectedTaskId,
                onEdit: _selectedTaskId != null
                    ? () {
                        final task = provider.tasks
                            .where((t) => t.id == _selectedTaskId)
                            .firstOrNull;
                        if (task != null) _handleEditTask(task);
                      }
                    : null,
                onFocus: (task) => _handleFocus(task),
              ),
          ],
        );
      },
    );
  }
}
