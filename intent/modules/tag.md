# Tag 模块 Intent

> 标签系统模块，为任务提供灵活的分类和筛选能力。

状态: draft
最后更新: 2026-02-08

## 职责

- 标签的 CRUD 操作
- 标签与任务的关联管理
- 基于标签的任务筛选

## 非目标

- 不做标签层级（标签保持扁平结构）
- 不做标签颜色自定义（使用预设颜色）

## 数据结构

```dart
// Tag Model (Freezed)
Tag {
  String id;
  String name;
  String? color;
  DateTime createdAt;
}
```

## API

```
TagRepositoryInterface
├── getAllTags() → ApiResponse<List<Tag>>
├── createTag(tag) → ApiResponse<Tag>
├── updateTag(tag) → ApiResponse<Tag>
└── deleteTag(id) → ApiResponse<void>
```
