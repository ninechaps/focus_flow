## 注册和登录流程
### 客户端注册流程

```
客户端 App                          Web 页面                         服务端
    │                                  │                               │
    │── 打开 浏览器  ──────────────────>│                               │
    │   /auth/register/client          │                               │
    │                                  │── POST /api/auth/send-code ──>│
    │                                  │<── 200 验证码已发送 ───────────│
    │                                  │                               │
    │                                  │   (用户输入验证码和密码)        │
    │                                  │                               │
    │                                  │── GET /api/auth/public-key ──>│
    │                                  │<── { publicKey: PEM } ────────│
    │                                  │   RSA-OAEP 加密密码            │
    │                                  │                               │
    │                                  │── POST /api/auth/register ───>│
    │                                  │   { encryptedPassword, ... }  │
    │                                  │<── 201 注册成功 ──────────────│
    │                                  │                               │
    │                                  │   显示"注册成功"              │
    │                                  │   5秒倒计时                    │
    │<── window.close() ───────────────│                               │
    │                                  │                               │
    │── GET /api/auth/public-key ─────────────────────────────────────>│
    │<── { publicKey: PEM } ──────────────────────────────────────────│
    │   RSA-OAEP 加密密码                                              │
    │                                                                  │
    │── POST /api/auth/login ─────────────────────────────────────────>│
    │   { encryptedPassword, deviceType: ios/android, ... }            │
    │<── 200 { accessToken, refreshToken, sessionId } ────────────────│
```

### 客户端登录流程

```
客户端 App                                                    服务端
    │                                                           │
    │── GET /api/auth/public-key ──────────────────────────────>│
    │<── { publicKey: PEM } ────────────────────────────────────│
    │                                                           │
    │   用户输入邮箱和密码                                        │
    │   RSA-OAEP + SHA-256 加密密码 → Base64 密文                │
    │                                                           │
    │── POST /api/auth/login ──────────────────────────────────>│
    │   {                                                       │
    │     "email": "user@example.com",                          │
    │     "encryptedPassword": "Base64...",  ← RSA 密文          │
    │     "deviceId": "device-001",                             │
    │     "deviceName": "iPhone 15 Pro",                        │
    │     "deviceType": "ios"                                   │
    │   }                                                       │
    │                                                           │
    │   服务端：私钥解密 → 验证密码 → 签发 token                  │
    │                                                           │
    │<── 200 ──────────────────────────────────────────────────│
    │   {                                                       │
    │     "success": true,                                      │
    │     "data": {                                             │
    │       "user": { ... },                                    │
    │       "accessToken": "eyJ...",                            │
    │       "refreshToken": "eyJ...",                           │
    │       "sessionId": "uuid"                                 │
    │     }                                                     │
    │   }                                                       │
    │                                                           │
    │   客户端：安全存储 token，后续请求携带                       │
    │   Authorization: Bearer {accessToken}                     │
```

## 一、认证接口

### 1.1 发送验证码

```
POST /api/auth/send-code
```

发送 6 位数字验证码到用户邮箱，用于注册或重置密码。

**鉴权：** 无

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 有效邮箱地址 |
| purpose | `"register"` \| `"reset"` | 否 | 验证码用途 |

**成功响应（200）：**

```json
{
  "success": true,
  "data": {
    "message": "Verification code sent"
  }
}
```

**错误码：**

| 状态码 | 说明 |
|--------|------|
| 400 | 请求参数错误 |
| 409 | 账号已存在（purpose 为 register 时） |
| 429 | 请求过于频繁 |

---

### 1.2 获取 RSA 公钥

```
GET /api/auth/public-key
```

获取服务端 RSA 公钥，客户端用此公钥加密密码。公钥是公开信息，无需鉴权。

**鉴权：** 无

**成功响应（200）：**

```json
{
  "success": true,
  "data": {
    "publicKey": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A...\n-----END PUBLIC KEY-----\n"
  }
}
```

**响应头：**

| Header | 值 | 说明 |
|--------|---|------|
| Cache-Control | `public, max-age=3600, stale-while-revalidate=86400` | 公钥可被 CDN 和客户端缓存 |

**错误码：**

| 状态码 | 说明 |
|--------|------|
| 500 | 服务端未配置 RSA 密钥 |

---

### 1.3 客户端注册

```
POST /api/auth/register
```

客户端专用注册接口。**只创建用户，不签发 token，不设 cookie/session。** 注册成功后客户端需自行调用 `POST /api/auth/login` 登录获取 token。

**鉴权：** 无

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 有效邮箱地址 |
| code | string | 是 | 6 位数字验证码 |
| encryptedPassword | string | 是 | RSA 加密后的密码（Base64），最长 512 字符。明文需满足：至少 8 位，包含大小写字母和数字 |
| username | string | 否 | 3-100 字符，仅允许字母、数字、下划线、连字符 |
| fullName | string | 否 | 最长 255 字符 |

**成功响应（201）：**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "johndoe",
      "fullName": "John Doe",
      "avatarUrl": null,
      "registrationSource": "jwt",
      "emailVerifiedAt": "2026-02-17T10:00:00.000Z",
      "createdAt": "2026-02-17T10:00:00.000Z",
      "lastLoginAt": "2026-02-17T10:00:00.000Z",
      "totalOnlineTime": 0
    }
  }
}
```

**错误码：**

| 状态码 | 说明 |
|--------|------|
| 400 | 请求参数错误 / 验证码无效或过期 / 密码解密失败 / 密码不符合复杂度要求 |
| 409 | 该邮箱已注册 |

---

### 1.4 客户端登录

```
POST /api/auth/login
```

客户端使用，返回 JSON 格式的 token。通过请求体中的 `deviceType` 标识设备来源。

**鉴权：** 无

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | 是 | 邮箱地址 |
| encryptedPassword | string | 是 | RSA 加密后的密码（Base64），最长 512 字符 |
| deviceId | string | 否 | 设备唯一标识，最长 255 字符 |
| deviceName | string | 否 | 设备名称，最长 255 字符 |
| deviceType | enum | 否 | `macos` / `ios` / `android` / `web` / `windows` / `linux` |

**成功响应（200）：**

```json
{
  "success": true,
  "data": {
    "user": { ... },
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "eyJhbGciOi...",
    "sessionId": "uuid"
  }
}
```

**错误码：**

| 状态码 | 说明 |
|--------|------|
| 400 | 请求参数错误 / 密码解密失败 |
| 401 | 邮箱或密码错误 |
| 403 | 邮箱未验证 |

---

### 1.5 刷新 Token

```
POST /api/auth/refresh
```

用旧的 refreshToken 换取新的 accessToken 和 refreshToken。旧 refreshToken 会被立即吊销（rotation 机制）。

**鉴权：** 无

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| refreshToken | string | 是 | 当前有效的刷新令牌 |

**成功响应（200）：**

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "eyJhbGciOi..."
  }
}
```

**错误码：**

| 状态码 | 说明 |
|--------|------|
| 400 | 请求参数错误 |
| 401 | refreshToken 无效、已过期或已被吊销 |
| 404 | 用户不存在 |

---

### 1.6 客户端退出登录

```
POST /api/auth/logout
```

吊销 refreshToken，结束 session，并将本次在线时长累加到用户总时长。

**鉴权：** JWT Bearer Token

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| refreshToken | string | 是 | 需要吊销的刷新令牌 |
| sessionId | string | 否 | 要结束的会话 ID（UUID） |

**成功响应（200）：**

```json
{
  "success": true,
  "data": {
    "message": "Logged out successfully"
  }
}
```

---

### 1.7 获取当前用户

```
GET /api/auth/me
```

获取当前已认证用户的个人信息、角色和权限列表。

**鉴权：** JWT Bearer Token

**成功响应（200）：**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "johndoe",
      "fullName": "John Doe",
      "avatarUrl": null,
      "registrationSource": "jwt",
      "emailVerifiedAt": "2026-02-17T10:00:00.000Z",
      "createdAt": "2026-02-17T10:00:00.000Z",
      "lastLoginAt": "2026-02-17T10:00:00.000Z",
      "totalOnlineTime": 3600
    },
    "roles": ["user", "admin"],
    "permissions": ["admin:users:read"]
  }
}
```

**错误码：**

| 状态码 | 说明 |
|--------|------|
| 404 | 用户不存在 |

---
