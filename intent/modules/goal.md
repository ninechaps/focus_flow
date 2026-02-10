# Goal 模块 Intent

> 目标管理模块，为任务提供可选的分组归属，帮助用户按目标组织任务。

状态: draft
最后更新: 2026-02-09

## 职责

- 目标的 CRUD 操作
- 作为任务的可选分组（Task.goalId 关联）
- 支持按目标筛选和分组任务

## 非目标

- 不做目标层级（目标保持扁平结构）
- 不做目标进度自动计算（由 UI 层根据任务完成数计算）
- 不做目标模板或推荐

## 数据结构

```dart
// Goal Model (Freezed)
Goal {
  String id;
  String name;
  DateTime dueDate;
  DateTime createdAt;
  DateTime updatedAt;
}
```

## 关键业务规则

1. 目标为可选概念，任务可以不属于任何目标
2. 删除目标不删除关联的任务（任务的 goalId 置空）
3. 目标进度 = 该目标下已完成任务数 / 总任务数（UI 层计算）

## API

### IGoalRepository

```
IGoalRepository
├── getAll() → ApiResponse<List<Goal>>
├── getById(id) → ApiResponse<Goal>
├── create(goal) → ApiResponse<Goal>
├── update(goal) → ApiResponse<Goal>
└── delete(id) → ApiResponse<void>
```
