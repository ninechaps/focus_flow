# Focus 模块 Intent

> 番茄钟专注计时模块，管理专注会话的开始、暂停、完成和数据记录。

状态: draft
最后更新: 2026-02-08

## 职责

- 番茄钟倒计时管理（工作时段 / 休息时段）
- 专注会话状态控制（开始、暂停、恢复、结束）
- 关联当前专注的任务
- 记录专注时长数据

## 非目标

- 不做统计分析（归 statistics 模块）
- 不做任务管理（归 task 模块）

## 数据结构

```dart
// FocusProvider 状态
FocusProvider {
  Duration remainingTime;
  bool isRunning;
  bool isBreak;
  Task? currentTask;
}
```

## API

```
FocusProvider
├── startFocus(task?) → void
├── pauseFocus() → void
├── resumeFocus() → void
├── stopFocus() → void
└── skipBreak() → void
```
