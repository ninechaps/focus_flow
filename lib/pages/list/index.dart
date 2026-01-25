import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../models/goal.dart';
import '../../models/tag.dart';
import '../../providers/task_provider.dart';
import 'widgets/task_filter_panel.dart';
import 'widgets/task_list_panel.dart';
import 'widgets/tips_panel.dart';
import 'widgets/add_tag_dialog.dart';
import 'widgets/add_goal_dialog.dart';
import 'widgets/add_task_dialog.dart';
import 'widgets/edit_tag_dialog.dart';
import 'widgets/edit_goal_dialog.dart';

/// List page - Main task list view with three-panel layout
/// Left: Filter panel (categories, time filters, tags)
/// Center: Task list grouped by time
/// Right: Tips and motivation panel
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
    // Initialize data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TaskProvider>();
      if (provider.tasks.isEmpty && !provider.isLoading) {
        provider.init();
      }
    });
  }

  void _handleTaskTap(Task task) {
    setState(() {
      // Select the task (no deselection on re-click)
      _selectedTaskId = task.id;
    });
  }

  void _handleFocus(Task task) {
    // Navigate to focus page with the task
    context.go('/app/focus/${task.id}');
  }

  Future<void> _handleAddSubtask(Task parentTask) async {
    final provider = context.read<TaskProvider>();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subtask added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add subtask: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleAddTask() async {
    final provider = context.read<TaskProvider>();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleAddTag() async {
    final provider = context.read<TaskProvider>();
    final tag = await showAddTagDialog(context);

    if (tag != null && mounted) {
      try {
        await provider.addTag(tag);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tag added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add tag: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleAddGoal() async {
    final provider = context.read<TaskProvider>();
    final goal = await showAddGoalDialog(context);

    if (goal != null && mounted) {
      try {
        await provider.addGoal(goal);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add goal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEditGoal(Goal goal) async {
    final provider = context.read<TaskProvider>();
    final updatedGoal = await showEditGoalDialog(context, goal);

    if (updatedGoal != null && mounted) {
      try {
        await provider.updateGoal(updatedGoal);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update goal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteGoal(String goalId) async {
    final provider = context.read<TaskProvider>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await provider.deleteGoal(goalId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Goal deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete goal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEditTag(Tag tag) async {
    final provider = context.read<TaskProvider>();
    final updatedTag = await showEditTagDialog(context, tag);

    if (updatedTag != null && mounted) {
      try {
        await provider.updateTag(updatedTag);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tag updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update tag: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteTag(String tagId) async {
    final provider = context.read<TaskProvider>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: const Text('Are you sure you want to delete this tag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await provider.deleteTag(tagId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tag deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete tag: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.tasks.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Check if right panel should be visible
        final bool showRightPanel = provider.selectedGoalId != null || _selectedTaskId != null;

        return Row(
          children: [
            // Left panel: Filter panel
            TaskFilterPanel(
              selectedTimeFilter: provider.selectedTimeFilter,
              selectedTagId: provider.selectedTagId,
              selectedGoalId: provider.selectedGoalId,
              tags: provider.tags,
              goals: provider.goals,
              tasks: provider.tasks,
              onTimeFilterChanged: (filter) {
                // Clear selected task when changing time filter
                setState(() {
                  _selectedTaskId = null;
                });
                provider.setTimeFilter(filter);
              },
              onTagChanged: provider.setTagFilter,
              onGoalChanged: provider.setGoalFilter,
              onAddTag: _handleAddTag,
              onAddGoal: _handleAddGoal,
              onEditGoal: _handleEditGoal,
              onDeleteGoal: _handleDeleteGoal,
              onEditTag: _handleEditTag,
              onDeleteTag: _handleDeleteTag,
            ),

            // Center panel: Task list (expands when right panel is hidden)
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
                onReorder: (groupKey, oldIndex, newIndex, groupTasks) async {
                  try {
                    await provider.reorderTasks(groupKey, oldIndex, newIndex, groupTasks);
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reorder tasks: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onSubtasksReorder: (parentTask, oldIndex, newIndex) async {
                  try {
                    final subtasks = provider.subtasksMap[parentTask.id] ?? [];
                    await provider.reorderTasks('subtasks_${parentTask.id}', oldIndex, newIndex, subtasks);
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reorder subtasks: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),

            // Right panel: Only show when goal or task is selected
            if (showRightPanel)
              TipsPanel(
                goals: provider.goals,
                tasks: provider.tasks,
                selectedGoalId: provider.selectedGoalId,
                selectedTaskId: _selectedTaskId,
              ),
          ],
        );
      },
    );
  }
}
