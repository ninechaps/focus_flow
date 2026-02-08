# Auth 模块 Intent

> 用户认证与 Profile 管理模块。

状态: draft
最后更新: 2026-02-08

## 职责

- 用户登录/注册流程
- 用户 Profile 信息管理
- 认证状态维护

## 非目标

- 不做第三方 OAuth 登录（当前阶段）
- 不做权限管理系统

## API

```
AuthProvider
├── login(email, password) → void
├── logout() → void
├── register(user) → void
└── updateProfile(user) → void
```
