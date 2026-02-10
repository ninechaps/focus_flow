# Task 模块 Intent

> 任务管理核心模块，支持任务的创建、编辑、删除、状态流转、父子层级关系、目标归属和专注时长追踪。

状态: draft
最后更新: 2026-02-09

## 职责

- 任务的完整 CRUD 操作
- 父子任务层级关系管理
- 任务状态流转（pending → inProgress → completed / deleted）
- 子任务完成联动逻辑（全部子任务完成 → 父任务自动完成）
- 任务优先级管理
- 任务与标签的关联（多对多）
- 任务与目标的关联（多对一）
- 任务截止日期管理
- 专注时长累计
- 拖拽排序

## 非目标

- 不处理番茄钟计时逻辑（归 focus 模块）
- 不处理日程安排逻辑（归 schedule 模块）
- 不做跨设备同步

## 数据结构

```dart
// Task Model (Freezed)
Task {
  String id;
  String title;
  String? description;
  DateTime? dueDate;          // 截止日期
  String? parentTaskId;       // 父任务 ID（null 表示顶级任务）
  String? goalId;             // 所属目标 ID
  Goal? goal;                 // 关联的 Goal 对象
  TaskPriority priority;      // high, medium, low
  TaskStatus status;          // pending, inProgress, completed, deleted
  List<Tag> tags;             // 关联标签列表，默认 []
  int focusDuration;          // 累计专注秒数，默认 0
  int sortOrder;              // 排序序号（拖拽排序），默认 0
  DateTime? completedAt;      // 完成时间戳
  DateTime createdAt;
  DateTime updatedAt;
}
```

### 枚举定义

```dart
enum TaskStatus {
  pending,      // 待处理
  inProgress,   // 进行中
  completed,    // 已完成
  deleted,      // 已删除（软删除）
}

enum TaskPriority {
  high,
  medium,
  low,
}
```

## 关键业务规则

1. 子任务可以自由完成
2. 有未完成子任务的父任务不能直接标记完成
3. 所有子任务完成时，父任务自动完成
4. 取消任一子任务完成状态时，父任务自动恢复为 pending
5. 删除使用软删除（status = deleted），不物理删除记录
6. 任务完成时记录 completedAt 时间戳
7. 专注时长通过 addFocusDuration 累加，不直接覆盖

## API

### ITaskRepository

```
ITaskRepository
├── getAll() → ApiResponse<List<Task>>
├── getById(id) → ApiResponse<Task>
├── getSubtasks(parentId) → ApiResponse<List<Task>>
├── getTopLevelTasks() → ApiResponse<List<Task>>
├── getSubtasksMap() → ApiResponse<Map<String, List<Task>>>
├── create(task) → ApiResponse<Task>
├── update(task) → ApiResponse<Task>
├── toggleStatus(id) → ApiResponse<Task>
├── delete(id) → ApiResponse<void>
├── search(query) → ApiResponse<List<Task>>
├── getByTag(tagId) → ApiResponse<List<Task>>
├── getByGoal(goalId) → ApiResponse<List<Task>>
├── getByDateRange(start, end) → ApiResponse<List<Task>>
├── addFocusDuration(id, durationInSeconds) → ApiResponse<Task>
└── updateSortOrders(Map<String, int>) → ApiResponse<void>
```
