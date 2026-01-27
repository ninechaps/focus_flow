import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/tag.dart';
import '../models/goal.dart';
import '../models/enums.dart';
import '../repositories/interfaces/task_repository_interface.dart';
import '../repositories/interfaces/tag_repository_interface.dart';
import '../repositories/interfaces/goal_repository_interface.dart';
import '../repositories/repository_provider.dart';

/// Provider for managing task-related state
/// Uses abstract repository interfaces for database operations
class TaskProvider extends ChangeNotifier {
  final ITaskRepository _taskRepository;
  final ITagRepository _tagRepository;
  final IGoalRepository _goalRepository;

  List<Task> _tasks = [];
  List<Tag> _tags = [];
  List<Goal> _goals = [];
  Map<String, List<Task>> _subtasksMap = {};

  bool _isLoading = false;
  String? _error;

  // Filter state
  String? _selectedTimeFilter = 'today';
  String? _selectedTagId;
  String? _selectedGoalId;
  String? _selectedStatusFilter = 'pending'; // Default to TODO tab, null = all
  String _searchQuery = '';

  TaskProvider({
    ITaskRepository? taskRepository,
    ITagRepository? tagRepository,
    IGoalRepository? goalRepository,
  })  : _taskRepository = taskRepository ?? RepositoryProvider.instance.taskRepository,
        _tagRepository = tagRepository ?? RepositoryProvider.instance.tagRepository,
        _goalRepository = goalRepository ?? RepositoryProvider.instance.goalRepository;

  // Getters
  List<Task> get tasks => _tasks;
  List<Tag> get tags => _tags;
  List<Goal> get goals => _goals;
  Map<String, List<Task>> get subtasksMap => _subtasksMap;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedTimeFilter => _selectedTimeFilter;
  String? get selectedTagId => _selectedTagId;
  String? get selectedGoalId => _selectedGoalId;
  String? get selectedStatusFilter => _selectedStatusFilter;
  String get searchQuery => _searchQuery;

  /// Get matching task IDs based on search query
  Set<String> _getMatchingTaskIds() {
    final matchingTaskIds = <String>{};

    if (_searchQuery.isEmpty) {
      return matchingTaskIds;
    }

    final query = _searchQuery.toLowerCase();

    for (final task in _tasks) {
      // Check if task matches search query
      final titleMatches = task.title.toLowerCase().contains(query);
      final descriptionMatches = task.description?.toLowerCase().contains(query) ?? false;
      final tagMatches = task.tags.any((tag) => tag.name.toLowerCase().contains(query));

      if (titleMatches || descriptionMatches || tagMatches) {
        matchingTaskIds.add(task.id);

        // If this is a subtask, also include its parent
        if (task.parentTaskId != null) {
          matchingTaskIds.add(task.parentTaskId!);
        }
      }
    }

    return matchingTaskIds;
  }

  /// Get filtered tasks based on current filters
  List<Task> get filteredTasks {
    var filtered = _tasks.where((t) => t.parentTaskId == null).toList();

    // Filter by search query (includes title, description, and tags)
    if (_searchQuery.isNotEmpty) {
      final matchingTaskIds = _getMatchingTaskIds();

      // Filter top-level tasks to only those that match or have matching subtasks
      filtered = filtered.where((t) {
        // Task itself matches
        if (matchingTaskIds.contains(t.id)) {
          return true;
        }

        // Check if any subtask matches
        final subtasks = _subtasksMap[t.id] ?? [];
        return subtasks.any((subtask) => matchingTaskIds.contains(subtask.id));
      }).toList();
    }

    // Filter by time (date-only comparisons)
    // For completed tasks, use completedAt; for others, use createdAt
    if (_selectedTimeFilter != null && _selectedTimeFilter != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      filtered = filtered.where((t) {
        // Use completedAt for completed tasks, createdAt for others
        final DateTime referenceDateTime;
        if (t.status == TaskStatus.completed && t.completedAt != null) {
          referenceDateTime = t.completedAt!;
        } else {
          referenceDateTime = t.createdAt;
        }
        final referenceDate = DateTime(
          referenceDateTime.year,
          referenceDateTime.month,
          referenceDateTime.day,
        );

        switch (_selectedTimeFilter) {
          case 'today':
            // All unfinished tasks + completed today
            if (t.status == TaskStatus.pending || t.status == TaskStatus.inProgress) {
              return true;
            }
            return referenceDate == today;
          case 'week':
            // All unfinished tasks + completed within past 7 days
            if (t.status == TaskStatus.pending || t.status == TaskStatus.inProgress) {
              return true;
            }
            final weekStart = today.subtract(const Duration(days: 6));
            return !referenceDate.isBefore(weekStart);
          case 'month':
            // All unfinished tasks + completed this month
            if (t.status == TaskStatus.pending || t.status == TaskStatus.inProgress) {
              return true;
            }
            return referenceDate.year == today.year && referenceDate.month == today.month;
          case 'earlier':
            // Before this month
            return referenceDate.isBefore(DateTime(today.year, today.month, 1));
          default:
            return true;
        }
      }).toList();
    }

    // Filter by tag
    if (_selectedTagId != null) {
      filtered = filtered.where((t) {
        return t.tags.any((tag) => tag.id == _selectedTagId);
      }).toList();
    }

    // Filter by goal
    if (_selectedGoalId != null) {
      filtered = filtered.where((t) {
        return t.goalId == _selectedGoalId;
      }).toList();
    }

    // Filter by status
    if (_selectedStatusFilter != null) {
      filtered = filtered.where((t) {
        switch (_selectedStatusFilter) {
          case 'pending':
            return t.status == TaskStatus.pending;
          case 'in_progress':
            return t.status == TaskStatus.inProgress;
          case 'completed':
            return t.status == TaskStatus.completed;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  /// Get top-level tasks filtered by time/tag/goal (but NOT status)
  /// Used for counting tasks per status in the tab badges
  List<Task> get tasksForStatusCounting {
    var filtered = _tasks.where((t) => t.parentTaskId == null).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final matchingTaskIds = _getMatchingTaskIds();
      filtered = filtered.where((t) {
        if (matchingTaskIds.contains(t.id)) return true;
        final subtasks = _subtasksMap[t.id] ?? [];
        return subtasks.any((subtask) => matchingTaskIds.contains(subtask.id));
      }).toList();
    }

    // Apply time filter (same logic as filteredTasks but for ALL statuses)
    if (_selectedTimeFilter != null && _selectedTimeFilter != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      filtered = filtered.where((t) {
        final DateTime referenceDateTime;
        if (t.status == TaskStatus.completed && t.completedAt != null) {
          referenceDateTime = t.completedAt!;
        } else {
          referenceDateTime = t.createdAt;
        }
        final referenceDate = DateTime(
          referenceDateTime.year,
          referenceDateTime.month,
          referenceDateTime.day,
        );

        switch (_selectedTimeFilter) {
          case 'today':
            if (t.status == TaskStatus.pending || t.status == TaskStatus.inProgress) {
              return true;
            }
            return referenceDate == today;
          case 'week':
            if (t.status == TaskStatus.pending || t.status == TaskStatus.inProgress) {
              return true;
            }
            final weekStart = today.subtract(const Duration(days: 6));
            return !referenceDate.isBefore(weekStart);
          case 'month':
            if (t.status == TaskStatus.pending || t.status == TaskStatus.inProgress) {
              return true;
            }
            return referenceDate.year == today.year && referenceDate.month == today.month;
          case 'earlier':
            return referenceDate.isBefore(DateTime(today.year, today.month, 1));
          default:
            return true;
        }
      }).toList();
    }

    // Apply tag filter
    if (_selectedTagId != null) {
      filtered = filtered.where((t) {
        return t.tags.any((tag) => tag.id == _selectedTagId);
      }).toList();
    }

    // Apply goal filter
    if (_selectedGoalId != null) {
      filtered = filtered.where((t) {
        return t.goalId == _selectedGoalId;
      }).toList();
    }

    // Note: NO status filter applied here — that's the point
    return filtered;
  }

  /// Get filtered subtasks map based on search query
  /// When searching, only return subtasks that match the search
  Map<String, List<Task>> get filteredSubtasksMap {
    // If no search query, return all subtasks
    if (_searchQuery.isEmpty) {
      return _subtasksMap;
    }

    // Get matching task IDs
    final matchingTaskIds = _getMatchingTaskIds();

    // Filter subtasks to only include matching ones
    final filteredMap = <String, List<Task>>{};

    for (final entry in _subtasksMap.entries) {
      final parentId = entry.key;
      final subtasks = entry.value;

      // Filter subtasks to only those that match the search
      final matchingSubtasks = subtasks.where((subtask) {
        return matchingTaskIds.contains(subtask.id);
      }).toList();

      // Only add to map if there are matching subtasks
      if (matchingSubtasks.isNotEmpty) {
        filteredMap[parentId] = matchingSubtasks;
      }
    }

    return filteredMap;
  }

  /// Initialize and load all data
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadTasks(),
        _loadTags(),
        _loadGoals(),
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing TaskProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTasks() async {
    final response = await _taskRepository.getAll();
    if (response.isSuccess && response.data != null) {
      _tasks = response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to load tasks');
    }

    final subtasksResponse = await _taskRepository.getSubtasksMap();
    if (subtasksResponse.isSuccess && subtasksResponse.data != null) {
      _subtasksMap = subtasksResponse.data!;
    }
  }

  Future<void> _loadTags() async {
    final response = await _tagRepository.getAll();
    if (response.isSuccess && response.data != null) {
      _tags = response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to load tags');
    }
  }

  Future<void> _loadGoals() async {
    final response = await _goalRepository.getAll();
    if (response.isSuccess && response.data != null) {
      _goals = response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to load goals');
    }
  }

  /// Refresh all data from storage
  Future<void> refresh() async {
    await init();
  }

  // Filter setters
  void setTimeFilter(String? filter) {
    _selectedTimeFilter = filter;
    notifyListeners();
  }

  void setTagFilter(String? tagId) {
    _selectedTagId = tagId;
    notifyListeners();
  }

  void setGoalFilter(String? goalId) {
    _selectedGoalId = goalId;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Task operations
  Future<void> addTask(Task task) async {
    try {
      // Auto-assign sortOrder based on existing tasks
      int sortOrder = 0;
      if (task.parentTaskId != null) {
        // For subtasks, get the count of existing subtasks under the same parent
        final existingSubtasks = _subtasksMap[task.parentTaskId] ?? [];
        sortOrder = existingSubtasks.length;
      } else {
        // For top-level tasks, get the count of existing top-level tasks
        final existingTopLevel = _tasks.where((t) => t.parentTaskId == null).toList();
        sortOrder = existingTopLevel.length;
      }

      // Create task with assigned sortOrder
      final taskWithSortOrder = task.copyWith(sortOrder: sortOrder);
      final response = await _taskRepository.create(taskWithSortOrder);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadTasks();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final response = await _taskRepository.update(task);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadTasks();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Task?> toggleTaskStatus(String taskId) async {
    try {
      final response = await _taskRepository.toggleStatus(taskId);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadTasks();
      notifyListeners();
      return response.data;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await _taskRepository.delete(taskId);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadTasks();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Tag operations
  Future<void> addTag(Tag tag) async {
    try {
      final response = await _tagRepository.create(tag);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadTags();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTag(Tag tag) async {
    try {
      final response = await _tagRepository.update(tag);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadTags();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTag(String tagId) async {
    try {
      final response = await _tagRepository.delete(tagId);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadTags();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Goal operations
  Future<void> addGoal(Goal goal) async {
    try {
      final response = await _goalRepository.create(goal);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadGoals();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      final response = await _goalRepository.update(goal);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadGoals();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      final response = await _goalRepository.delete(goalId);
      if (response.isError) {
        throw Exception(response.message);
      }
      await _loadGoals();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Clear all data from the database
  /// WARNING: This will delete all tasks, tags, and goals
  /// For testing purposes only - remove before production release
  Future<void> clearAllData() async {
    try {
      await RepositoryProvider.instance.clearAllData();
      await init();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Generate a unique ID for new entities
  String generateId() {
    return const Uuid().v4();
  }

  /// Reorder tasks within a group
  Future<void> reorderTasks(String groupKey, int oldIndex, int newIndex, List<Task> groupTasks) async {
    try {
      // Adjust newIndex if moving down
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // Create a copy of the list to reorder
      final reorderedTasks = List<Task>.from(groupTasks);
      final movedTask = reorderedTasks.removeAt(oldIndex);
      reorderedTasks.insert(newIndex, movedTask);

      // Update sort orders for all tasks in this group
      final Map<String, int> sortOrderUpdates = {};
      for (int i = 0; i < reorderedTasks.length; i++) {
        sortOrderUpdates[reorderedTasks[i].id] = i;
      }

      // Update in database
      final response = await _taskRepository.updateSortOrders(sortOrderUpdates);
      if (response.isError) {
        throw Exception(response.message);
      }

      // Reload tasks to get updated order
      await _loadTasks();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
