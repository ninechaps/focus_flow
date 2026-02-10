# Focus 模块 Intent

> 番茄钟专注计时模块，管理专注会话的开始、暂停、完成、休息和数据记录，支持倒计时/正计时两种模式。

状态: draft
最后更新: 2026-02-09

## 职责

- 番茄钟倒计时管理（工作时段 / 休息时段）
- 正计时（Stopwatch）模式支持
- 专注会话状态控制（选择任务 → 开始 → 暂停/恢复 → 完成 → 休息）
- 关联当前专注的任务，累计专注时长
- 记录每次专注会话到数据库
- 每日专注统计（总时长、会话数）
- 番茄钟预设方案管理

## 非目标

- 不做统计分析（归 statistics 模块）
- 不做任务管理（归 task 模块）
- 不做白噪音/环境音

## 状态机

```
FocusState:
  idle → ready → running → paused → running (循环)
                    │                   │
                    └→ completed → breaking → ready (下一轮)
                    │                   │
                    │                   └→ ready (跳过休息)
                    │
                    └→ stopped (手动停止 → idle)
```

| 状态 | 含义 |
|------|------|
| idle | 未选择任务 |
| ready | 已选任务，计时器未启动 |
| running | 计时器运行中 |
| paused | 计时器暂停 |
| completed | 专注时段完成（倒计时归零或手动完成） |
| breaking | 休息时段进行中 |

## 计时模式

```dart
enum TimerMode {
  countdown, // 倒计时：从目标时间倒数到 0，自动完成
  countUp,   // 正计时：从 0 开始累计，手动停止
}
```

- 用户可在 ready 状态下切换模式
- 模式选择通过 SharedPreferences 持久化

## 番茄钟预设

```dart
class PomodoroPreset {
  String id;
  String name;
  int workMinutes;
  int breakMinutes;
}

// 内置预设（不持久化到数据库）
static const defaults = [
  PomodoroPreset(id: 'sprint',   name: 'Sprint',     workMinutes: 15, breakMinutes: 3),
  PomodoroPreset(id: 'pomodoro', name: 'Pomodoro',   workMinutes: 25, breakMinutes: 5),
  PomodoroPreset(id: 'deep',     name: 'Deep Focus', workMinutes: 50, breakMinutes: 10),
  PomodoroPreset(id: 'marathon', name: 'Marathon',    workMinutes: 90, breakMinutes: 20),
];
```

- 选择预设自动设置 workMinutes 和 breakMinutes
- 手动修改时长会清除预设（切换到自定义模式）

## 数据结构

### FocusSession (Freezed, 持久化到 SQLite)

```dart
FocusSession {
  String id;
  String taskId;
  DateTime startedAt;
  DateTime? endedAt;
  int durationSeconds;    // 本次会话实际专注时长
  int targetSeconds;      // 倒计时模式下的目标秒数（正计时为 0）
  String timerMode;       // 'countdown' | 'countUp'
  String completionType;  // 'completed' | 'stopped'
  DateTime createdAt;
}
```

### FocusProvider 运行时状态

```dart
FocusProvider {
  FocusState state;           // 当前状态
  Task? currentTask;          // 当前专注任务
  int elapsedSeconds;         // 累计已用时间（包含之前的专注时间）
  int sessionStartSeconds;    // 本次会话开始时的 elapsed 值
  int targetMinutes;          // 目标时长（分钟），默认 25
  TimerMode timerMode;        // 当前计时模式
  PomodoroPreset? currentPreset;  // 当前选中的预设
  int todayTotalSeconds;      // 今日总专注秒数（来自数据库）
  int todaySessionCount;      // 今日会话数（来自数据库）
  List<FocusSession> taskSessions; // 当前任务的历史会话
}
```

## 关键业务规则

1. **累计专注时间**：每次 startFocusSession 时从 task.focusDuration 恢复已有时长，stop/complete 时仅保存本次新增的时间
2. **倒计时自动完成**：countdown 模式下 elapsed >= target 时自动触发 completeSession
3. **正计时无上限**：countUp 模式不自动完成，需手动停止
4. **休息机制**：仅当预设有 breakMinutes > 0 时才提供休息，completed → breaking → ready
5. **会话记录**：每次 stop 或 complete 时保存 FocusSession 到数据库
6. **模式持久化**：timerMode 通过 SharedPreferences 持久化，clearFocus 时恢复到已保存的模式

## API

### FocusProvider (ChangeNotifier)

```
FocusProvider
├── startFocusSession(task, {durationMinutes?}) → void  // 选择任务，进入 ready
├── start() → void                     // 开始计时
├── pause() → void                     // 暂停计时
├── resume() → void                    // 恢复计时
├── stop() → Future<void>              // 停止并保存会话
├── completeSession() → Future<void>   // 完成并保存会话
├── resetForNextSession() → void       // 重置为 ready（保留累计时间）
├── startBreak() → void               // 进入休息时段
├── skipBreak() → void                // 跳过休息
├── toggleTimerMode() → void          // 切换倒计时/正计时
├── setTimerMode(mode) → void         // 直接设置模式
├── selectPreset(preset) → void       // 选择预设
├── clearPreset() → void              // 清除预设（自定义模式）
├── setTargetMinutes(minutes) → void  // 设置目标时长
├── clearFocus() → void               // 清除所有状态回到 idle
│
├── [getters]
│   ├── state → FocusState
│   ├── currentTask → Task?
│   ├── elapsedSeconds → int
│   ├── targetMinutes / targetSeconds → int
│   ├── remainingSeconds → int
│   ├── sessionSeconds → int          // 本次会话新增秒数
│   ├── timerMode → TimerMode
│   ├── currentPreset → PomodoroPreset?
│   ├── todayTotalSeconds / todaySessionCount → int
│   ├── taskSessions → List<FocusSession>
│   ├── isRunning / isPaused / isBreaking / isActive → bool
│   ├── isCountdown / isCountUp → bool
│   ├── hasBreak → bool
│   ├── progress → double (0.0~1.0)
│   ├── formattedTime → String
│   ├── formattedElapsedTime → String
│   ├── formattedSessionTime → String
│   ├── formattedTodayTotalTime → String
│   ├── breakRemainingSeconds → int
│   ├── breakProgress → double
│   └── formattedBreakTime → String
│
└── dispose() → void
```

### IFocusSessionRepository

```
IFocusSessionRepository
├── create(session) → ApiResponse<FocusSession>
├── getByTask(taskId) → ApiResponse<List<FocusSession>>
├── getByDateRange(start, end) → ApiResponse<List<FocusSession>>
├── getTodaySummary() → ApiResponse<Map<String, int>>
└── delete(id) → ApiResponse<void>
```

## 依赖

- `ITaskRepository.addFocusDuration(id, seconds)` — 保存专注时长到任务
- `IFocusSessionRepository` — 保存/查询专注会话
- `SharedPreferences` — 持久化 TimerMode
- `dart:async (Timer)` — 每秒 tick
