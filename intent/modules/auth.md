# Auth 模块 Intent

> 对接外部认证服务 API，实现 RSA 加密登录、JWT Token 管理、自动刷新、路由守卫，注册通过浏览器跳转 Web 页面完成。

状态: draft
最后更新: 2026-02-17

---

## 1. 背景与目标

### 现状

当前认证模块使用硬编码凭据（admin/admin123）进行本地验证，无真实的身份认证能力。

### 目标

- 对接外部 REST API 认证服务，实现真实的用户登录/登出
- 密码使用 RSA-OAEP + SHA-256 非对称加密传输，不明文传输
- 使用 JWT（accessToken + refreshToken + sessionId）管理会话
- Token 安全存储于 macOS Keychain（通过 flutter_secure_storage）
- 实现路由守卫，未认证用户无法访问受保护页面
- Token 过期时自动静默刷新，用户无感
- 注册通过跳转浏览器 Web 页面完成

### 非目标

- 不在客户端内实现注册表单（注册走 Web 页面）
- 不做第三方 OAuth 登录（当前阶段）
- 不做权限/角色管理
- 不做数据层多用户隔离（单用户桌面端，数据天然属于当前登录用户）

---

## 2. 整体架构

### 2.1 分层结构

```
┌─────────────────────────────────────────────────────────┐
│                       UI Layer                           │
│  LoginPage (邮箱+密码+注册跳转) │ AppShell (受保护页面)    │
├─────────────────────────────────────────────────────────┤
│                    Route Guard                           │
│  GoRouter.redirect → 检查 AuthProvider.isAuthenticated   │
│  已认证 + /login → 重定向 /app/list                       │
│  未认证 + /app/* → 重定向 /login                          │
├─────────────────────────────────────────────────────────┤
│                  State Management                        │
│  AuthProvider (ChangeNotifier)                           │
│  管理认证状态、User 信息、错误状态                           │
├─────────────────────────────────────────────────────────┤
│                  Repository Layer                        │
│  AuthRepositoryInterface (抽象接口)                       │
│       ↓ 实现                                             │
│  HttpAuthRepository (调用远程 API)                        │
├─────────────────────────────────────────────────────────┤
│                   Network Layer                          │
│  Dio HTTP Client + AuthInterceptor                      │
│  自动附加 Token │ 401 拦截 │ Token 刷新 │ 重发请求         │
├─────────────────────────────────────────────────────────┤
│                  Security Layer                          │
│  RsaEncryptService (RSA-OAEP + SHA-256 密码加密)         │
│  AuthStorage (flutter_secure_storage / macOS Keychain)  │
└─────────────────────────────────────────────────────────┘
```

### 2.2 数据流概览

```
LoginPage ──login(email, password)──→ AuthProvider
                                          │
                                          ↓
                                   1. GET /api/auth/public-key → 获取 RSA 公钥
                                   2. RSA-OAEP + SHA-256 加密密码 → Base64 密文
                                   3. POST /api/auth/login { email, encryptedPassword, device* }
                                          │
                                          ↓
                                   认证服务返回:
                                   { success, data: { user, accessToken, refreshToken, sessionId } }
                                          │
                                          ↓
                                   AuthProvider 处理响应:
                                   ├── 存储 tokens + sessionId → SecureStorage
                                   ├── 解析/存储 User 信息
                                   ├── 设置 isAuthenticated = true
                                   └── notifyListeners()
                                          │
                                          ↓
                                   GoRouter 监听状态变化 → 跳转 /app/list
```

---

## 3. 详细流程设计

### 3.1 登录流程

```
用户输入邮箱/密码，点击登录
        │
        ↓
LoginPage._handleLogin()
        │
        ↓
AuthProvider.login(email, password)
  ├── 1. 前端校验
  │     ├── 邮箱格式校验
  │     ├── 密码非空、最小长度
  │     └── 校验失败 → 设置 errorMessage → return false
  │
  ├── 2. 设置 isLoading = true，notifyListeners()
  │
  ├── 3. 获取 RSA 公钥
  │     └── AuthRepository.getPublicKey()
  │         └── Dio GET /api/auth/public-key
  │         └── 返回 { publicKey: "-----BEGIN PUBLIC KEY-----\n..." }
  │
  ├── 4. 加密密码
  │     └── RsaEncryptService.encrypt(password, publicKey)
  │         ├── 解析 PEM 格式公钥
  │         ├── RSA-OAEP + SHA-256 加密
  │         └── Base64 编码 → encryptedPassword
  │
  ├── 5. 调用登录接口
  │     └── AuthRepository.login(loginRequest)
  │         └── Dio POST /api/auth/login
  │             {
  │               "email": "user@example.com",
  │               "encryptedPassword": "Base64...",
  │               "deviceId": "macOS-uuid",
  │               "deviceName": "MacBook Pro",
  │               "deviceType": "macos"
  │             }
  │
  ├── 6. 处理响应
  │     ├── 成功 (200, success: true):
  │     │   ├── 从 data 中解析 accessToken, refreshToken, sessionId, user
  │     │   ├── 存储 tokens + sessionId → SecureStorage
  │     │   ├── 存储 User 信息 → SecureStorage
  │     │   ├── 设置 _currentUser, _isAuthenticated = true
  │     │   └── return true
  │     │
  │     └── 失败 (401/其他):
  │         ├── 解析错误信息
  │         ├── 设置 _errorMessage
  │         └── return false
  │
  └── 7. 设置 isLoading = false，notifyListeners()

GoRouter.redirect 监听到 isAuthenticated 变化
  └── 已认证 + 当前在 /login → 重定向到 /app/list
```

### 3.2 注册流程

```
用户在登录页点击"注册"链接
        │
        ↓
url_launcher 打开系统浏览器
  └── 访问 {baseUrl}/auth/register/client
        │
        ↓
Web 页面上完成注册:
  1. 输入邮箱 → POST /api/auth/send-code → 发送验证码
  2. 输入验证码 + 设置密码
  3. GET /api/auth/public-key → 获取 RSA 公钥
  4. RSA-OAEP 加密密码
  5. POST /api/auth/register → 提交注册
  6. 注册成功 → 显示成功提示 → 5 秒倒计时 → window.close()
        │
        ↓
用户回到客户端 App
  └── 手动输入邮箱/密码登录（不自动登录）

注意: 客户端不实现注册表单，只提供跳转入口。
```

### 3.3 应用启动流程（Token 恢复与验证）

```
App 启动 → main()
        │
        ↓
AuthProvider 构造函数
  └── _initAuth() 异步初始化
        │
        ├── 1. 从 SecureStorage 读取 accessToken
        │     └── 无 token → _isAuthenticated = false → 结束
        │
        ├── 2. 有 token → 尝试验证
        │     └── 调用 AuthRepository.getCurrentUser()
        │         └── Dio GET /api/auth/me (自动附加 Bearer token)
        │
        ├── 3. 处理验证结果
        │     ├── 成功 (200):
        │     │   ├── 解析 User 信息，更新 _currentUser
        │     │   ├── _isAuthenticated = true
        │     │   └── notifyListeners() → GoRouter 重定向到 /app/list
        │     │
        │     ├── Token 过期 (401):
        │     │   └── AuthInterceptor 自动触发 refresh 流程（见 3.4）
        │     │       ├── 刷新成功 → 重发请求 → 走成功分支
        │     │       └── 刷新失败 → 走失败分支
        │     │
        │     └── 失败（网络错误/服务不可用）:
        │         ├── 清除存储的 tokens
        │         ├── _isAuthenticated = false
        │         └── notifyListeners() → GoRouter 保持在 /login
        │
        └── 4. _isInitialized = true，notifyListeners()

GoRouter.redirect 中需要处理初始化中的状态:
  └── 未初始化完成 → 不做重定向（避免闪烁）
```

### 3.4 Token 自动刷新流程

```
任意 API 请求发出（由 AuthInterceptor 处理）
        │
        ↓
请求拦截器（onRequest）
  └── 从 SecureStorage 读取 accessToken
      └── 附加 Header: Authorization: Bearer <accessToken>
        │
        ↓
服务端响应
        │
        ├── 正常响应 (2xx) → 直接返回
        │
        └── 401 Unauthorized → 进入刷新流程
              │
              ├── 1. 检查是否已在刷新中（防止并发刷新）
              │     └── 是 → 将本次请求加入等待队列
              │
              ├── 2. 从 SecureStorage 读取 refreshToken
              │     └── 无 refreshToken → 触发登出
              │
              ├── 3. 调用 POST /api/auth/refresh { refreshToken }
              │     （注意：此请求不经过 AuthInterceptor，避免循环）
              │
              ├── 4. 处理刷新结果
              │     ├── 成功 (200):
              │     │   ├── 存储新的 accessToken (+ 新 refreshToken，如果有)
              │     │   ├── 用新 token 重发原始请求
              │     │   └── 释放等待队列中的请求（用新 token 重发）
              │     │
              │     └── 失败 (401/其他):
              │         ├── 清除所有 tokens
              │         ├── 通知 AuthProvider 执行 logout
              │         ├── 拒绝等待队列中的所有请求
              │         └── GoRouter 重定向到 /login
              │
              └── 5. 重置刷新锁
```

### 3.5 路由守卫流程

```
用户导航到任意路由
        │
        ↓
GoRouter.redirect(context, state)
        │
        ├── 读取 AuthProvider 状态
        │
        ├── 情况1: 未初始化完成（_isInitialized == false）
        │   └── return null（不重定向，保持当前页面）
        │
        ├── 情况2: 未认证 + 目标是 /app/*
        │   └── return '/login'（强制跳转登录页）
        │
        ├── 情况3: 已认证 + 目标是 /login
        │   └── return '/app/list'（已登录不需要再看登录页）
        │
        └── 情况4: 其他
            └── return null（允许正常导航）

触发时机:
  - 每次路由变化
  - AuthProvider notifyListeners() 时（通过 refreshListenable 监听）
```

### 3.6 登出流程

```
用户点击登出（UserAvatarMenu）
        │
        ↓
AuthProvider.logout()
  ├── 1. 可选: 调用 AuthRepository.logout()
  │     └── Dio POST /api/auth/logout（通知服务端销毁 session）
  │         └── 失败也不影响本地登出
  │
  ├── 2. 清除 SecureStorage 中的 tokens、sessionId、User 信息
  │
  ├── 3. 重置内存状态
  │     ├── _isAuthenticated = false
  │     ├── _currentUser = null
  │     └── _errorMessage = null
  │
  └── 4. notifyListeners()
            │
            ↓
      GoRouter.redirect 触发
        └── 未认证 → 重定向到 /login
```

---

## 4. API 接口规范

### 4.1 接口列表

| 方法 | 路径 | 认证 | 说明 |
|------|------|:----:|------|
| GET | `/api/auth/public-key` | 否 | 获取 RSA 公钥（PEM 格式） |
| POST | `/api/auth/login` | 否 | 邮箱+加密密码登录 |
| POST | `/api/auth/refresh` | 否 | 刷新 accessToken |
| GET | `/api/auth/me` | Bearer | 获取当前用户信息 |
| POST | `/api/auth/logout` | Bearer | 登出（销毁服务端 session） |

### 4.2 登录请求/响应

**请求 POST /api/auth/login**

```json
{
  "email": "user@example.com",
  "encryptedPassword": "Base64...",
  "deviceId": "macOS-unique-id",
  "deviceName": "MacBook Pro",
  "deviceType": "macos"
}
```

**响应 200**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "displayName"
    },
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "sessionId": "uuid"
  }
}
```

### 4.3 获取公钥响应

**响应 GET /api/auth/public-key**

```json
{
  "publicKey": "-----BEGIN PUBLIC KEY-----\nMIIBI...\n-----END PUBLIC KEY-----"
}
```

---

## 5. 数据结构

### 5.1 User 模型（扩展）

```dart
@freezed
abstract class User with _$User {
  const factory User({
    required String id,          // 新增: 服务端用户唯一标识
    required String username,
    required String email,       // 改为必填: 登录凭证
    DateTime? lastLoginTime,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 5.2 登录请求模型

```dart
@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String encryptedPassword,
    required String deviceId,
    required String deviceName,
    required String deviceType,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}
```

### 5.3 认证响应模型

```dart
@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    required String refreshToken,
    required String sessionId,
    required User user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
```

### 5.4 SecureStorage Key 定义

```dart
abstract class AuthStorageKeys {
  static const accessToken = 'auth_access_token';
  static const refreshToken = 'auth_refresh_token';
  static const sessionId = 'auth_session_id';
  static const userInfo = 'auth_user_info';
  static const deviceId = 'auth_device_id';
}
```

> Token 和 sessionId 不放在 User 模型中，由 SecureStorage 单独管理，避免泄露到 UI 层。

---

## 6. 接口设计

### 6.1 AuthRepositoryInterface

```dart
abstract class AuthRepositoryInterface {
  /// 获取 RSA 公钥（PEM 格式）
  Future<ApiResponse<String>> getPublicKey();

  /// 用户登录
  Future<ApiResponse<AuthResponse>> login(LoginRequest request);

  /// 使用 refreshToken 刷新 accessToken
  Future<ApiResponse<AuthResponse>> refreshToken(String refreshToken);

  /// 获取当前用户信息（验证 token 有效性）
  Future<ApiResponse<User>> getCurrentUser();

  /// 登出
  Future<ApiResponse<void>> logout();
}
```

### 6.2 RsaEncryptService

```dart
class RsaEncryptService {
  /// 使用 RSA-OAEP + SHA-256 加密明文密码，返回 Base64 编码的密文
  static String encrypt(String plainText, String publicKeyPem);
}
```

### 6.3 DeviceInfoService

```dart
class DeviceInfoService {
  /// 获取或生成持久化的设备 ID（存储在 SecureStorage）
  static Future<String> getDeviceId();

  /// 获取设备名称（macOS 主机名）
  static String getDeviceName();

  /// 获取设备类型（固定返回 "macos"）
  static String getDeviceType();
}
```

### 6.4 AuthProvider API

```
AuthProvider (ChangeNotifier)
├── login(email, password) → Future<bool>
├── logout() → Future<void>
├── openRegisterPage() → Future<void>    // 新增: 打开浏览器注册页
├── clearError() → void
│
├── [getters]
│   ├── isAuthenticated → bool
│   ├── isInitialized → bool
│   ├── isLoading → bool
│   ├── errorMessage → String?
│   └── currentUser → User?
│
└── [内部]
    ├── _initAuth() → Future<void>
    ├── _storeTokens(auth) → Future
    ├── _clearTokens() → Future
    └── _storeUserInfo(user) → Future
```

---

## 7. 错误处理

### 7.1 错误码映射

| 场景 | 错误代码 | UI 行为 |
|------|---------|--------|
| 邮箱/密码为空 | `empty_credentials` | 表单校验提示 |
| 邮箱格式无效 | `invalid_email` | 表单校验提示 |
| 凭证错误 | `invalid_credentials` | 显示错误信息 |
| 公钥获取失败 | `encryption_error` | 显示加密服务异常 |
| 网络不可达 | `network_error` | 显示网络错误提示 |
| 服务器错误 | `server_error` | 显示服务异常提示 |
| Token 刷新失败 | `session_expired` | 跳转登录页，提示会话过期 |

### 7.2 网络异常处理策略

```
Dio 请求异常
  ├── DioExceptionType.connectionTimeout → network_error
  ├── DioExceptionType.receiveTimeout → network_error
  ├── DioExceptionType.connectionError → network_error
  ├── 状态码 401 → AuthInterceptor 处理（刷新或登出）
  ├── 状态码 403 → invalid_credentials
  └── 状态码 500+ → server_error
```

---

## 8. 文件结构

### 8.1 新增文件

```
lib/
├── core/
│   ├── api/
│   │   ├── api_response.dart              # 已有，保持不变
│   │   └── http_client.dart               # 新增: Dio 封装 + 单例
│   ├── auth/
│   │   ├── auth_interceptor.dart          # 新增: Token 拦截器 + 自动刷新
│   │   └── auth_storage.dart              # 新增: SecureStorage 封装
│   └── crypto/
│       └── rsa_encrypt_service.dart       # 新增: RSA-OAEP 加密服务
├── models/
│   ├── user.dart                          # 修改: 新增 id 字段，email 改必填
│   ├── auth_response.dart                 # 新增: 认证响应模型
│   └── login_request.dart                 # 新增: 登录请求模型
├── repositories/
│   ├── interfaces/
│   │   └── auth_repository_interface.dart # 新增: 认证仓库接口
│   └── http/
│       └── http_auth_repository.dart      # 新增: HTTP 认证仓库实现
├── services/
│   └── device_info_service.dart           # 新增: 设备信息采集
├── providers/
│   └── auth_provider.dart                 # 修改: 全面改造
└── router.dart                            # 修改: 添加 redirect 路由守卫
```

### 8.2 修改文件

| 文件 | 改动内容 |
|------|---------|
| `pubspec.yaml` | 新增 dio、flutter_secure_storage、pointycastle、url_launcher 依赖 |
| `lib/models/user.dart` | 新增 `id` 字段，`email` 改为 required |
| `lib/providers/auth_provider.dart` | 全面改造：接入 AuthRepository、RSA 加密、SecureStorage |
| `lib/router.dart` | 添加 `redirect` 和 `refreshListenable` |
| `lib/main.dart` | AuthProvider 注入依赖、初始化顺序调整 |
| `lib/widgets/auth_wrapper.dart` | 移除（职责被路由守卫接管） |
| `lib/pages/login/index.dart` | 邮箱登录表单 + 注册跳转链接 + 移除 demo 提示 |

---

## 9. 新增依赖

| Package | 用途 | 桌面端支持 |
|---------|------|:----------:|
| `dio` | HTTP 客户端，拦截器、超时、取消 | ✅ |
| `flutter_secure_storage` | 加密存储（macOS Keychain） | ✅ |
| `pointycastle` | RSA-OAEP + SHA-256 加密 | ✅ 纯 Dart |
| `url_launcher` | 打开系统浏览器（注册页面） | ✅ |

---

## 10. 实施步骤

### Step 1: 添加依赖 + 基础配置

**目标**: 项目能引入新依赖并正常编译

**操作**:
- `pubspec.yaml` 添加 dio、flutter_secure_storage、pointycastle、url_launcher
- 运行 `flutter pub get` 验证依赖无冲突
- macOS 平台配置: Keychain 权限（entitlements）、网络权限

**产出**: 项目正常编译，新依赖可用

**验证**: `flutter build macos` 无报错

---

### Step 2: 实现安全存储层（AuthStorage）

**目标**: 封装 flutter_secure_storage，提供 token 读写能力

**操作**:
- 新建 `lib/core/auth/auth_storage.dart`
- 定义 AuthStorageKeys 常量
- 封装 read/write/delete/clear 方法
- deviceId 首次生成后持久化存储

**产出**: `AuthStorage` 类，可独立运行

**验证**: 单元测试写入/读取/删除 token

---

### Step 3: 实现 RSA 加密服务

**目标**: 能用服务端公钥加密密码

**操作**:
- 新建 `lib/core/crypto/rsa_encrypt_service.dart`
- 解析 PEM 格式公钥
- 实现 RSA-OAEP + SHA-256 加密
- 输出 Base64 编码密文

**产出**: `RsaEncryptService.encrypt(plainText, pemKey)` → Base64 密文

**验证**: 用测试公钥加密，确认输出为有效 Base64 字符串

---

### Step 4: 实现 Dio HTTP 客户端

**目标**: 封装 Dio 实例，统一 baseUrl、超时、日志

**操作**:
- 新建 `lib/core/api/http_client.dart`
- 配置 baseUrl（从环境变量或常量读取）
- 配置 connectTimeout / receiveTimeout
- 添加日志拦截器（debug 模式）
- 预留 AuthInterceptor 挂载点

**产出**: `HttpClient` 单例，提供 Dio 实例

**验证**: 能发送 GET /api/auth/public-key 并收到响应

---

### Step 5: 定义数据模型

**目标**: 创建登录相关的 Freezed 数据模型

**操作**:
- 修改 `lib/models/user.dart`: 新增 `id` 字段，`email` 改为 required
- 新建 `lib/models/login_request.dart`: LoginRequest 模型
- 新建 `lib/models/auth_response.dart`: AuthResponse 模型
- 运行 `build_runner` 生成代码
- 修复 User 模型变更导致的编译错误（全项目搜索 User 构造调用）

**产出**: 三个 Freezed 模型 + 生成的序列化代码

**验证**: `dart run build_runner build` 无报错，`flutter analyze` 通过

---

### Step 6: 实现 AuthRepository

**目标**: 封装认证相关 API 调用

**操作**:
- 新建 `lib/repositories/interfaces/auth_repository_interface.dart`
  - 定义 getPublicKey / login / refreshToken / getCurrentUser / logout
- 新建 `lib/repositories/http/http_auth_repository.dart`
  - 实现接口，调用 Dio 发送 HTTP 请求
  - 统一返回 ApiResponse 包装
- 新建 `lib/services/device_info_service.dart`
  - getDeviceId（SecureStorage 持久化）
  - getDeviceName（macOS 主机名）
  - getDeviceType（固定 "macos"）

**产出**: AuthRepository 可调用登录/刷新/获取用户接口

**验证**: 手动调用 login 方法，确认能正确发送加密密码并收到 token

---

### Step 7: 实现 AuthInterceptor（Token 拦截器）

**目标**: 自动附加 token + 401 时自动刷新

**操作**:
- 新建 `lib/core/auth/auth_interceptor.dart`
- onRequest: 读取 accessToken → 附加 Authorization header
- onError: 捕获 401 → 加锁 → 刷新 token → 重发请求
- 并发控制: Completer 队列，防止多次刷新
- 刷新失败: 回调通知外部执行 logout
- 将 AuthInterceptor 挂载到 HttpClient

**产出**: 请求自动带 token，401 自动刷新，刷新失败自动登出

**验证**: 模拟 token 过期 → 观察自动刷新 → 请求成功重发

---

### Step 8: 改造 AuthProvider

**目标**: 替换硬编码逻辑，接入真实 API

**操作**:
- 构造函数注入 AuthRepositoryInterface（依赖注入，便于测试）
- 移除硬编码凭据和 SharedPreferences 逻辑
- login(): 获取公钥 → RSA 加密 → 构建 LoginRequest → 调用 Repository → 存储 tokens
- logout(): 调用 Repository.logout() → 清除 SecureStorage → 重置状态
- _initAuth(): 启动时从 SecureStorage 恢复 token → 调 getCurrentUser 验证
- 新增 isInitialized getter
- 新增 openRegisterPage(): url_launcher 打开注册 Web 页面
- AuthInterceptor 的 onForceLogout 回调绑定到 logout()

**产出**: AuthProvider 完全对接远程认证服务

**验证**: 完整登录/登出/启动恢复流程测试

---

### Step 9: 实现路由守卫

**目标**: 未认证用户无法访问受保护页面

**操作**:
- 修改 `lib/router.dart`:
  - router() 接收 AuthProvider 参数
  - 添加 `redirect` 回调（四种情况判断）
  - 添加 `refreshListenable` 监听 AuthProvider
- 修改 `lib/main.dart`:
  - 将 AuthProvider 传入 router()
  - 移除 AuthWrapper 的使用
- 删除 `lib/widgets/auth_wrapper.dart`（职责已被路由守卫接管）

**产出**: 路由自动守护，未认证跳登录页，已认证跳主页

**验证**:
- 未登录直接访问 /app/list → 自动跳转 /login
- 已登录访问 /login → 自动跳转 /app/list
- 登出后自动跳回 /login

---

### Step 10: 更新登录页 UI

**目标**: 适配新的邮箱登录 + 注册跳转

**操作**:
- 修改 `lib/pages/login/index.dart`:
  - 用户名输入框 → 邮箱输入框（加邮箱格式校验）
  - 移除 demo 凭证提示
  - 添加"注册账号"链接（调用 AuthProvider.openRegisterPage()）
  - 适配新的错误码（network_error、encryption_error 等）
  - 更新 i18n 文案

**产出**: 登录页适配真实认证服务

**验证**: 完整 UI 操作测试

---

### Step 11: 集成测试 + 清理

**目标**: 端到端验证全部流程，清理废弃代码

**操作**:
- 端到端测试:
  - 冷启动（无 token）→ 显示登录页
  - 登录成功 → 跳转主页
  - 关闭 App → 重新打开 → 自动恢复登录
  - Token 过期 → 自动刷新 → 用户无感
  - RefreshToken 过期 → 跳转登录页
  - 登出 → 跳转登录页
  - 注册链接 → 打开浏览器
- 清理:
  - 移除 SharedPreferences 中旧的 user_login_info key
  - 移除 auth_wrapper.dart
  - 确认 dart analyze 无警告

**产出**: 全部流程可用，代码干净

---

## 11. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| RSA 加密在 Dart 中性能 | 登录时有短暂延迟 | pointycastle 是纯 Dart 实现，性能足够；加密操作仅在登录时执行一次 |
| 认证服务不可用（网络断开） | 桌面端无法登录 | 启动时网络不可达，清除 token 跳转登录页（桌面端要求在线使用） |
| flutter_secure_storage macOS 兼容性 | 存储失败 | 该 package 已支持 macOS + Keychain，风险较低 |
| Token 并发刷新竞态 | 多个请求同时 401 | AuthInterceptor 使用 Completer 锁，仅允许一次 refresh |
| 公钥获取失败 | 无法加密密码 | 登录流程中优先获取公钥，失败则提示 encryption_error |
| User 模型变更影响现有代码 | 编译错误 | Step 5 中统一修复所有 User 构造调用 |

---

## 12. 待确认事项

- [ ] 认证服务的 baseUrl
- [ ] accessToken 和 refreshToken 的过期时间
- [ ] /api/auth/me 接口是否存在（用于启动时验证 token）
- [ ] /api/auth/refresh 的请求/响应格式
- [ ] /api/auth/logout 是否为必需接口
- [ ] 注册页面的完整 URL 路径
- [ ] API 响应中 user 对象的具体字段
