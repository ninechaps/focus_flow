# Platform 模块 Intent

> macOS 系统集成模块，提供菜单栏计时器、NSPopover 预览面板、全局快捷键和原生通知能力。

状态: draft
最后更新: 2026-02-09

## 职责

- macOS 菜单栏显示番茄钟倒计时和状态图标
- NSPopover 面板：左键点击菜单栏图标弹出专注状态预览
- 右键上下文菜单：快捷操作（开始/暂停/停止/打开应用/退出）
- 全局快捷键绑定（开始/暂停/停止专注、打开窗口）
- 番茄钟结束时推送 macOS 原生通知
- 国际化支持：菜单、通知、popover 文案跟随应用语言切换

## 非目标

- 不做 Windows/Linux 系统集成（当前阶段）
- 不做 Touch Bar 支持
- 不做 Spotlight 集成
- 不做 Widgets（macOS 桌面小组件）

## 架构：三服务编排模式

```
PlatformIntegrationService (编排者)
├── NativeTrayService      — 菜单栏图标 + NSPopover + 右键菜单
├── HotkeyService          — 全局快捷键注册
└── NotificationService    — macOS 系统通知
```

`PlatformIntegrationService` 监听 `FocusProvider` 的状态变化，将状态转换为平台级操作（图标切换、标题更新、通知推送），委派给对应的子服务执行。

### 状态转换映射

| FocusState | 菜单栏图标 | 标题 | 通知 |
|------------|----------|------|------|
| idle | 默认(灰) | (空) | — |
| ready | 默认(灰) | (空) | — |
| running | 活跃(彩) | 🍅 MM:SS | — |
| paused | 活跃(彩) | ⏸ MM:SS | — |
| completed | 默认(灰) | ✓ | "Focus Complete!" |
| breaking | 活跃(彩) | ☕ MM:SS | — |
| breaking→ready | 默认(灰) | (空) | "Break Over" |

## 关键交互

### NSPopover (左键点击)

```
┌─────────────────────────────┐
│  Focus Session              │
│  ┌───────────────────────┐  │
│  │ ● Focusing            │  │
│  │   23:45               │  │
│  │   Task: 写代码         │  │
│  │   ████████░░ 80%      │  │
│  └───────────────────────┘  │
│                             │
│  This Session   12:30       │
│  Total Focus    2h 15m      │
│  Sessions       5           │
│                             │
│  [⏸ Pause]  [⏹ Stop]      │
│  [Open Focus Hut]           │
└─────────────────────────────┘
```

Popover 使用 SwiftUI 实现（macOS 原生），通过 MethodChannel 与 Flutter 双向通信：
- Flutter → Swift：`updatePopoverState` 推送状态数据和本地化字符串
- Swift → Flutter：`onPopoverAction` 回调用户操作（pause/resume/stop/showWindow）

### 右键上下文菜单

```
┌──────────────────┐
│ 写代码            │  ← 当前任务（disabled）
│ 23:45            │  ← 剩余时间（disabled）
│ ──────────────── │
│ ⏸ Pause          │  ← 主操作（根据状态切换）
│ ⏹ Stop           │
│ ──────────────── │
│ Open Focus Hut   │
│ ──────────────── │
│ Quit             │
└──────────────────┘
```

### 全局快捷键

| 快捷键 | 动作 |
|--------|------|
| Cmd+Shift+F | 开始/暂停专注（toggle） |
| Cmd+Shift+S | 停止专注 |
| Cmd+Shift+O | 打开/聚焦主窗口 |

### 通知策略

- 番茄钟工作时段结束 → 通知"Focus Complete!"
- 休息时段结束 → 通知"Break Over"

## 国际化支持

`PlatformLocalizedStrings` 数据类包含所有平台层文案（菜单、通知、popover），在应用语言切换时通过 `updateLocalizedStrings()` 更新，并即时刷新菜单和 popover。

## API

### PlatformIntegrationService (编排者)

```
PlatformIntegrationService
├── init() → Future<void>                           // 初始化三个子服务 + 监听 FocusProvider
├── setRouter(router) → void                        // 设置路由（用于从 tray 导航到专注页）
├── updateLocalizedStrings(strings) → void           // 更新本地化文案
├── dispose() → Future<void>                         // 清理监听器和子服务
│
└── [内部 - 监听 FocusProvider 自动触发]
    ├── _onFocusStateChanged() → void               // 每次 notifyListeners 调用
    ├── _onStateTransition(from, to) → Future<void> // 状态转换处理
    ├── _updateTrayTitle() → Future<void>           // 更新菜单栏标题
    ├── _updateTrayMenu() → Future<void>            // 重建右键菜单
    ├── _syncPopoverState() → Future<void>          // 同步 popover 数据
    └── _sendCompletionNotification() → Future<void>
```

### NativeTrayService (MethodChannel: com.focusflow/tray)

```
NativeTrayService
├── init() → Future<void>
├── setIcon(assetPath, {isTemplate}) → Future<void>
├── setActiveIcon() → Future<void>
├── setDefaultIcon() → Future<void>
├── updateTitle(title) → Future<void>
├── setToolTip(toolTip) → Future<void>
├── updateContextMenu({...}) → Future<void>
├── updatePopoverState({...}) → Future<void>
├── dispose() → Future<void>
│
├── [回调]
│   ├── onStartPause → TrayActionCallback?
│   ├── onStop → TrayActionCallback?
│   ├── onShowWindow → TrayActionCallback?
│   └── onQuit → TrayActionCallback?
│
└── [MethodChannel 方法]
    ├── Flutter → Swift: setIcon, setTitle, setToolTip, setContextMenu, updatePopoverState, destroy
    └── Swift → Flutter: onPopoverAction, onMenuItemClick
```

### HotkeyService (hotkey_manager)

```
HotkeyService
├── init() → Future<void>     // 注册全局快捷键
├── dispose() → Future<void>  // 注销所有快捷键
│
└── [回调]
    ├── onStartPause → HotkeyActionCallback?
    ├── onStop → HotkeyActionCallback?
    └── onShowWindow → HotkeyActionCallback?
```

### NotificationService (flutter_local_notifications)

```
NotificationService
├── init() → Future<void>                                    // 初始化 + 请求权限
├── showWorkSessionComplete({taskName, duration, title, body}) → Future<void>
├── showBreakComplete({title, body}) → Future<void>
└── dispose() → Future<void>                                 // 取消所有通知
```

## 技术选型

| 能力 | 方案 | 状态 |
|------|------|------|
| 菜单栏 + Popover | Platform Channel (MethodChannel) + Swift NSStatusItem + NSPopover + SwiftUI | ✅ 已实现 |
| 全局快捷键 | hotkey_manager | ✅ 已实现 |
| 系统通知 | flutter_local_notifications | ✅ 已实现 |
