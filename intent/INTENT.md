# Focus Hut Intent

> macOS 桌面端个人专注力管理工具，将任务管理与番茄钟无缝融合，以"选任务 → 专注 → 完成"的极简工作流帮助用户进入心流状态。

状态: reviewed
最后更新: 2026-02-08

---

::: reviewed {date=2026-02-08}
## 1. 产品定位

### 一句话定义

Focus Hut 是一款**轻量、极简**的 macOS 桌面应用，核心体验是**任务 + 专注一体化**。

### 目标用户

独立开发者、知识工作者 —— 需要管理日常任务并保持深度专注的个人用户。

### 差异化

| 维度 | 竞品现状 | Focus Hut |
|------|---------|-----------|
| 功能定位 | Todoist 只做任务，Forest 只做计时 | 任务 + 专注无缝融合 |
| 平台体验 | 多数是移动端移植 | 原生桌面体验（菜单栏、快捷键、托盘） |
| 复杂度 | Things 3 功能丰富但重 | 轻量极简，不做项目管理 |

### 核心工作流

```
打开应用 → 查看任务列表 → 选择一个任务 → 进入沉浸式专注
     ↓                                          ↓
  规划今日任务                          全屏倒计时 + 实时专注数据
                                                ↓
                                     番茄钟结束 → 任务完成 → 查看统计
```

### 产品阶段

**功能完善期** — 核心体验（任务管理 + 番茄钟）已确定，正在补全功能和打磨细节。
:::

---

::: reviewed {date=2026-02-08}
## 2. 架构概览

```
┌──────────────────────────────────────────────────────┐
│                    Platform Layer                     │
│  macOS Menu Bar │ System Tray │ Global Shortcuts      │
│  Notifications │ Window Management                    │
├──────────────────────────────────────────────────────┤
│                      UI Layer                        │
│  Pages: list │ focus(immersive) │ schedule │ stats   │
│  Widgets: shared │ layout │ dialogs                  │
│  Design: Material 3 + 自定义设计语言                   │
├──────────────────────────────────────────────────────┤
│                 State Management                     │
│  Provider (ChangeNotifier)                           │
│  TaskProvider │ FocusProvider │ ThemeProvider │ Auth  │
├──────────────────────────────────────────────────────┤
│                  Repository Layer                    │
│  Abstract Interfaces → SQLite Implementations        │
│  ApiResponse 统一返回格式                              │
│  预留云同步接口                                        │
├──────────────────────────────────────────────────────┤
│                    Data Layer                         │
│  SQLite (sqflite_common_ffi) │ SharedPreferences     │
│  Freezed Models (不可变数据模型)                        │
└──────────────────────────────────────────────────────┘
```
:::

---

::: reviewed {date=2026-02-08}
## 3. 技术栈

| 领域 | 方案 | 版本 |
|------|------|------|
| 框架 | Flutter/Dart | SDK ^3.10.0 |
| 设计语言 | Material Design 3 + 自定义视觉风格 | — |
| 状态管理 | Provider (ChangeNotifier) | ^6.1.5 |
| 路由 | GoRouter (ShellRoute) | ^17.0.0 |
| 数据库 | SQLite (sqflite_common_ffi) | ^2.3.4 |
| 代码生成 | Freezed + JSON Serializable | ^3.0.0 |
| 国际化 | Flutter L10n (zh/en) | intl ^0.20.2 |
| 窗口管理 | bitsdojo_window | ^0.1.5 |
:::

---

::: reviewed {date=2026-02-08}
## 4. 模块索引

| 模块 | 职责 | 成熟度 | Intent |
|------|------|--------|--------|
| task | 任务 CRUD、子任务层级、状态流转 | ✅ 成熟 | [task](modules/task.md) |
| focus | 番茄钟计时、沉浸式专注、专注会话 | 🔧 需完善 | [focus](modules/focus.md) |
| schedule | 日程视图、任务时间安排 | 🏗️ 框架级 | [schedule](modules/schedule.md) |
| statistics | 专注数据统计与可视化 | 🏗️ 框架级 | [statistics](modules/statistics.md) |
| auth | 本地账户、简化登录 | 🔧 需简化 | [auth](modules/auth.md) |
| theme | Light/Dark 切换、自定义设计语言 | ✅ 成熟 | [theme](modules/theme.md) |
| tag | 标签系统管理 | ✅ 成熟 | [tag](modules/tag.md) |
| platform | macOS 系统集成（菜单栏/托盘/快捷键/通知） | 🆕 待建 | [platform](modules/platform.md) |
:::

---

::: reviewed {date=2026-02-08}
## 5. 演进路线

### Phase 1: 系统集成（最高优先级）

让 Focus Hut 成为真正的"桌面应用"：
- macOS 菜单栏计时器（不切换窗口即可查看倒计时）
- 全局快捷键（任何应用中开始/暂停专注）
- 系统托盘（最小化时驻留）
- 系统通知（番茄钟结束提醒）

### Phase 2: 专注模式沉浸体验

打磨核心体验：
- 沉浸式全屏专注界面
- 实时专注数据（今日专注时长、连续专注次数）
- 番茄钟预设方案（25/5、50/10、90/20）+ 自定义参数
- 专注会话记录

### Phase 3: 统计可视化

形成正反馈循环：
- 专注时长图表（日/周/月）
- 任务完成率与趋势
- 效率指标与洞察

### Phase 4: 日程规划

完善时间管理维度：
- 日历视图完善
- 任务拖拽安排到时间段
- 今日计划视图
:::

---

::: reviewed {date=2026-02-08}
## 6. 关键决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 核心流程 | 任务驱动型 | 用户先选任务再专注，而非先计时 |
| 专注界面 | 沉浸式全屏 | 减少干扰，帮助进入心流 |
| Goal 概念 | 可选分组 | 不强制，保持轻量 |
| Auth | 保留但简化 | 本地账户为主，为云同步预留 |
| 番茄钟参数 | 预设 + 自定义 | 满足不同工作习惯 |
| 数据存储 | 本地 SQLite + 预留云接口 | 当前专注本地体验，Repository 接口可扩展 |
| 视觉风格 | Material 3 + 自定义设计语言 | 在 MD3 基础上建立辨识度 |
| 优先级 | 集成 > 专注 > 统计 > 日程 | 先建立桌面级体验差异化 |
:::

---

::: reviewed {date=2026-02-08}
## 7. 非目标

- 不做云端同步（当前阶段）
- 不做团队协作
- 不做移动端适配
- 不做复杂项目管理（甘特图、看板、Sprint）
- 不做社交功能（排行榜、共同专注）
- 不做白噪音/环境音（当前阶段）
:::

---

::: reviewed {date=2026-02-08}
## 8. 约束

### 技术约束
- macOS 桌面端为主要目标平台
- Provider 作为状态管理方案
- Freezed 保证数据模型不可变
- Repository 模式 + ApiResponse 统一返回格式
- 数据库接口设计预留云同步扩展能力

### 工程约束
- 优先使用成熟社区 package
- 文件 kebab-case、类 PascalCase、变量 camelCase
- 代码质量优先于交付速度
- 每次修改通过 Dart Analysis
- UI 遵循自定义设计语言规范（待建立）
:::

---

::: reviewed {date=2026-02-08}
## 9. 风险

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| macOS 系统集成 package 不成熟 | 菜单栏/托盘功能受限 | 提前调研 package，必要时用 Platform Channel |
| 自定义设计语言增加工作量 | 开发周期延长 | 渐进式推进，先做核心组件 |
| 番茄钟全屏与系统集成冲突 | 全屏时菜单栏不可见 | 设计优雅的降级方案 |
| SQLite 性能瓶颈（大量专注记录） | 统计查询变慢 | 索引优化 + 数据归档策略 |
:::

---

::: reviewed {date=2026-02-08}
## 10. 待定事项

- [ ] 自定义设计语言的设计规范（色彩、间距、组件风格）
- [ ] macOS 系统集成的具体 package 选型
- [ ] 专注会话数据模型设计
- [ ] 统计图表的具体指标定义
- [ ] 日程功能的详细交互设计
:::
