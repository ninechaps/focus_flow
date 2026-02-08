# Task 模块 Intent

> 任务管理核心模块，支持任务的创建、编辑、删除、状态流转和父子层级关系。

状态: draft
最后更新: 2026-02-08

## 职责

- 任务的完整 CRUD 操作
- 父子任务层级关系管理
- 任务状态流转（pending → completed）
- 子任务完成联动逻辑（全部子任务完成 → 父任务自动完成）
- 任务优先级管理
- 任务与标签的关联

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
  TaskStatus status;      // pending, completed
  Priority priority;      // low, medium, high
  String? parentTaskId;   // 父任务 ID（null 表示顶级任务）
  String? goalId;
  DateTime createdAt;
  DateTime updatedAt;
}
```

## 关键业务规则

1. 子任务可以自由完成
2. 有未完成子任务的父任务不能直接标记完成
3. 所有子任务完成时，父任务自动完成
4. 取消任一子任务完成状态时，父任务自动恢复为 pending

## API

```
TaskRepositoryInterface
├── getAllTasks() → ApiResponse<List<Task>>
├── getTaskById(id) → ApiResponse<Task>
├── createTask(task) → ApiResponse<Task>
├── updateTask(task) → ApiResponse<Task>
├── deleteTask(id) → ApiResponse<void>
├── getSubtasks(parentId) → ApiResponse<List<Task>>
└── toggleTaskStatus(id) → ApiResponse<Task>
```
