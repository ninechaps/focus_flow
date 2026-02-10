# Locale 模块 Intent

> 应用语言管理模块，支持中文/英文切换和语言偏好持久化。

状态: draft
最后更新: 2026-02-09

## 职责

- 管理应用当前语言设置
- 语言偏好持久化（SharedPreferences）
- 支持跟随系统语言（默认）或手动选择

## 非目标

- 不做语言包动态下载
- 不做 RTL 语言支持

## 支持的语言

| 语言代码 | 语言 |
|---------|------|
| zh | 简体中文 |
| en | English |
| (null) | 跟随系统 |

## 机制

- `locale == null` 表示跟随系统语言
- 设置语言后立即通过 `notifyListeners()` 触发 UI 重建
- 持久化到 SharedPreferences，key 为 `locale`，值为语言代码字符串或 `'system'`
- 应用启动时从 SharedPreferences 恢复，若值为 `'system'` 或不存在则保持 null

## 与 Platform 模块的联动

语言切换时，`PlatformIntegrationService.updateLocalizedStrings()` 需要同步更新，确保菜单栏、popover、通知的文案跟随语言变化。

## API

```
LocaleProvider (ChangeNotifier)
├── setLocale(locale?) → Future<void>  // 设置语言，null 表示跟随系统
│
├── [getters]
│   └── locale → Locale?              // null = 跟随系统
│
└── [内部]
    └── _loadLocale() → Future<void>   // 启动时从 SharedPreferences 恢复
```

## 使用方式

在 `MaterialApp` 中设置：

```dart
MaterialApp(
  locale: localeProvider.locale,  // null 时 Flutter 自动使用系统语言
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
)
```
