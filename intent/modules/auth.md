# Auth 模块 Intent

> 本地用户认证模块，提供简化的登录/登出和认证状态持久化。

状态: draft
最后更新: 2026-02-09

## 职责

- 用户登录/登出流程
- 认证状态维护与持久化（SharedPreferences）
- 错误状态管理

## 非目标

- 不做用户注册（当前使用固定凭据）
- 不做第三方 OAuth 登录（当前阶段）
- 不做权限管理系统
- 不做用户 Profile 编辑

## 数据结构

```dart
// User Model
User {
  String username;
  String email;
  DateTime lastLoginTime;
}
```

## 认证机制

- 使用固定的本地凭据（username: admin, password: admin123）
- 登录成功后将 User 信息 JSON 序列化存储到 SharedPreferences
- 应用启动时自动从 SharedPreferences 恢复登录状态
- 登出时清除存储的登录信息

## 错误处理

AuthProvider 返回错误代码（非本地化字符串），由 UI 层映射为本地化文本：

| 错误代码 | 含义 |
|---------|------|
| `empty_credentials` | 用户名或密码为空 |
| `invalid_credentials` | 用户名或密码错误 |

## API

```
AuthProvider (ChangeNotifier)
├── login(username, password) → Future<bool>
├── logout() → Future<void>
├── clearError() → void
├── validateStoredLogin() → Future<void>
│
├── [getters]
│   ├── isAuthenticated → bool
│   ├── isLoading → bool
│   ├── errorMessage → String?
│   └── currentUser → User?
│
└── [内部]
    ├── _loadStoredLoginInfo() → Future<void>  // 启动时恢复
    ├── _saveLoginInfo(user) → Future<void>     // 登录后保存
    └── _clearStoredLoginInfo() → Future<void>  // 登出时清除
```
