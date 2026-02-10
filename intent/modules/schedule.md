# Schedule 模块 Intent

> 日程视图模块，以日历形式展示任务安排，支持按日期查看和管理任务。

状态: draft
最后更新: 2026-02-09

## 职责

- 月历视图展示任务分布
- 按日期查看该日任务列表
- 任务优先级在日历上的可视化提示（彩色圆点）
- 月份导航和"回到今天"

## 非目标

- 不做日历同步（如 iCal、Google Calendar）
- 不做重复任务规则
- 不做任务拖拽到时间段（当前阶段）
- 不做周视图/日视图（当前只有月视图）

## 布局

```
┌─────────────────────────────────────────────┐
│  SchedulePage                                │
│  ┌─────────────────────┬───────────────────┐ │
│  │  Calendar Panel     │  Task List Panel  │ │
│  │  (flex: 3)          │  (flex: 2)        │ │
│  │                     │                   │ │
│  │  ← 2026年2月 →     │  2月9日 周一       │ │
│  │  [Today]            │                   │ │
│  │  Mo Tu We Th Fr Sa Su │                 │ │
│  │                     │  ● Task 1 [待处理] │ │
│  │   1  2  3  4  5     │  ● Task 2 [进行中] │ │
│  │   6  7  8  9 10     │  ● Task 3 [已完成] │ │
│  │  ...                │  ...              │ │
│  └─────────────────────┴───────────────────┘ │
└─────────────────────────────────────────────┘
```

## 数据流

- 直接消费 `TaskProvider.tasks` 列表
- 过滤条件：顶级任务（parentTaskId == null）、非删除（status != deleted）、有截止日期（dueDate != null）
- 按 dueDate 建立 `Map<DateTime, List<Task>>` 映射
- 日历使用周一起始、6 行 × 7 列共 42 格
- 日历格上的优先级圆点：收集该日所有任务的不同优先级，最多显示 3 个（high → medium → low 排序）

## 日期格式化

使用 `intl` 包的 `DateFormat` 实现 locale-aware 格式化：
- 月份导航标题：`DateFormat.yMMMM(locale)`
- 星期头：`DateFormat.E(locale)`
- 选中日期标题：`DateFormat.MMMEd(locale)`

## API

本模块为纯 UI 层，不定义独立的 Repository，数据来源于：

```
TaskProvider
├── tasks → List<Task>           // 所有任务
└── (通过 dueDate 过滤和分组)
```

### SchedulePage 内部方法

```
SchedulePage (StatefulWidget)
├── _filterTasks(tasks) → List<Task>            // 过滤有效任务
├── _buildDateTaskMap(tasks) → Map<DateTime, List<Task>>  // 按日期分组
├── _calendarDates(month) → List<DateTime>      // 生成 42 格日历
├── _goToPreviousMonth() → void
├── _goToNextMonth() → void
├── _goToToday() → void
├── _selectDate(date) → void
├── _priorityColor(priority) → Color
├── _statusColor(status) → Color
└── _statusLabel(status) → String
```
