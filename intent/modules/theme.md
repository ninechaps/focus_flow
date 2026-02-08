# Theme 模块 Intent

> 主题管理模块，支持 Light/Dark 模式切换与用户偏好持久化。

状态: draft
最后更新: 2026-02-08

## 职责

- Light/Dark 主题切换
- 跟随系统外观模式
- 主题偏好持久化（SharedPreferences）
- Material Design 3 主题定义

## 非目标

- 不做自定义主题色
- 不做主题市场/下载

## API

```
ThemeProvider
├── themeMode → ThemeMode
├── toggleTheme() → void
└── setThemeMode(mode) → void
```
