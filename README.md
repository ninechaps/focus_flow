# Focus Flow

Focus Flow is a Flutter desktop application for task management with Pomodoro-style focus timer functionality.

## 快速开始 | Getting Started

### 前置要求 | Prerequisites

确保您已安装以下工具：

- **Flutter SDK** (^3.10.0) - [安装指南](https://docs.flutter.dev/get-started/install)
- **Dart SDK** - 通常随 Flutter 一起安装
- **支持的桌面平台**：
  - macOS 10.14 或更高版本
  - Windows 10 或更高版本
  - Linux (Ubuntu 18.04 或更高版本)

验证 Flutter 安装：
```bash
flutter --version
```

### 安装依赖 | Installation

1. **克隆或进入项目目录**
   ```bash
   cd focus_flow
   ```

2. **获取项目依赖**
   ```bash
   flutter pub get
   ```

3. **生成代码**（使用 Freezed 和 JSON Serializable）
   ```bash
   flutter pub run build_runner build
   ```

   或使用监听模式，自动生成代码变化：
   ```bash
   flutter pub run build_runner watch
   ```

### 运行应用 | Running

#### 开发模式
```bash
flutter run
```

首次运行时，Flutter 会自动选择可用的平台。您也可以指定特定平台：

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

#### 发布版本构建
```bash
# macOS
flutter build macos

# Windows
flutter build windows

# Linux
flutter build linux
```

构建输出文件将位于 `build/` 目录下对应的平台文件夹中。

### 项目结构 | Project Structure

```
lib/
├── main.dart                 # 应用入口
├── core/                     # 核心逻辑（路由、主题、配置）
├── data/                     # 数据层（Repository、Model、数据源）
├── domain/                   # 业务逻辑层（Entity、Use Case）
├── presentation/             # 展示层（UI、Provider 状态管理）
└── l10n/                     # 国际化文件
```

### 更多资源 | More Resources

- [Flutter 文档](https://docs.flutter.dev/)
- [Dart 文档](https://dart.dev/guides)
- [Provider 状态管理文档](https://pub.dev/packages/provider)
- [GoRouter 路由文档](https://pub.dev/packages/go_router)

