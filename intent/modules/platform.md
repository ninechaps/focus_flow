# Platform 模块 Intent

> macOS 系统集成模块，提供菜单栏计时器、全局快捷键、系统托盘和原生通知能力。

状态: draft
最后更新: 2026-02-08

## 职责

- macOS 菜单栏显示番茄钟倒计时
- 全局快捷键绑定（开始/暂停/停止专注）
- 系统托盘驻留（最小化时保持运行）
- 番茄钟结束时推送 macOS 原生通知

## 非目标

- 不做 Windows/Linux 系统集成（当前阶段）
- 不做 Touch Bar 支持
- 不做 Spotlight 集成
- 不做 Widgets（macOS 桌面小组件）

## 关键交互

```
┌─────────────────────────────────────────────────┐
│ macOS Menu Bar                                   │
│  ┌──────────┐                                    │
│  │ 🍅 23:45 │  ← 菜单栏图标 + 剩余时间           │
│  └────┬─────┘                                    │
│       ├── 当前任务: 写代码                         │
│       ├── ──────────                              │
│       ├── ▶ 开始专注                               │
│       ├── ⏸ 暂停                                  │
│       ├── ⏹ 停止                                  │
│       ├── ──────────                              │
│       ├── 今日专注: 3h 25m                         │
│       ├── ──────────                              │
│       └── 打开 Focus Hut                          │
└─────────────────────────────────────────────────┘
```

### 全局快捷键方案

| 快捷键 | 动作 |
|--------|------|
| Cmd+Shift+F | 开始/暂停专注 |
| Cmd+Shift+S | 停止专注 |
| Cmd+Shift+O | 打开/聚焦主窗口 |

### 通知策略

- 番茄钟工作时段结束 → 通知"休息时间"
- 休息时段结束 → 通知"继续工作"
- 支持通知中的快捷操作（开始下一轮/跳过休息）

## API

```
PlatformService (待设计)
├── initMenuBar() → void
├── updateMenuBarTimer(remaining) → void
├── registerGlobalShortcuts() → void
├── showNotification(title, body, actions?) → void
├── initSystemTray() → void
└── dispose() → void
```

## 技术选型（待确认）

| 能力 | 候选方案 | 备注 |
|------|---------|------|
| 菜单栏 | tray_manager / macos_ui / Platform Channel | 需调研 |
| 全局快捷键 | hotkey_manager / Platform Channel | 需调研 |
| 系统通知 | flutter_local_notifications / Platform Channel | 需调研 |
| 系统托盘 | tray_manager / system_tray | 需调研 |
