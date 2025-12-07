# Mihomo Flutter Cross 开发者文档

## 项目架构

Mihomo Flutter Cross采用三层混合架构设计：

```
┌─────────────────────────────────────────┐
│           Flutter UI Layer              │
│  (Dart) - Material 3 + Widgets          │
├─────────────────────────────────────────┤
│          Bridge Layer                   │
│  (MethodChannel/FFI) - Cross-language   │
├─────────────────────────────────────────┤
│           Go Core Layer                 │
│  (Go) - TUN + Config + Networking       │
└─────────────────────────────────────────┘
```

### 技术栈
- **前端**: Flutter 3.24.0+ (Dart)
- **后端**: Go 1.21+
- **数据库**: Hive (Flutter)
- **TUN**: Android VpnService / iOS NEPacketTunnelProvider
- **跨语言桥接**: MethodChannel (Mobile) / FFI (Desktop)

## 开发环境搭建

### 系统要求
- **操作系统**: macOS 12+ / Ubuntu 20.04+ / Windows 10+
- **内存**: 16GB+ (推荐32GB)
- **存储**: 50GB+ 可用空间

### 开发工具安装

#### 1. Flutter SDK
```bash
# 下载Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
tar xf flutter_linux_3.24.0-stable.tar.xz

# 配置环境变量
export PATH="$PATH:`pwd`/flutter/bin"

# 添加到shell配置
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# 验证安装
flutter doctor
```

#### 2. Go SDK
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install golang-go

# 或手动安装
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# 验证安装
go version
```

#### 3. Android开发环境
```bash
# 安装Android Studio
# 下载地址: https://developer.android.com/studio

# 配置Android SDK
flutter config --android-studio-dir /path/to/android-studio

# 安装SDK组件
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# 接受许可证
sdkmanager --licenses
```

#### 4. iOS开发环境 (仅macOS)
```bash
# 安装Xcode (通过App Store)
# 安装Xcode命令行工具
sudo xcode-select --install

# 安装CocoaPods
sudo gem install cocoapods
```

### 项目设置

#### 1. 克隆项目
```bash
git clone <repository-url>
cd clash_cccc
```

#### 2. 初始化Flutter
```bash
cd flutter_app
flutter pub get
flutter doctor
```

#### 3. 配置开发环境
```bash
# 返回项目根目录
cd ..

# 运行构建脚本初始化
bash scripts/build_all_platforms.sh --clean
```

## 项目结构详解

```
clash_cccc/
├── flutter_app/                    # Flutter应用主目录
│   ├── lib/源码                        # Dart
│   │   ├── main.dart              # 应用入口
│   │   ├── ui/                    # 界面组件
│   │   │   ├── main_dashboard.dart # 主仪表板
│   │   │   └── config_panel.dart   # 配置面板
│   │   ├── storage/               # 数据存储
│   │   │   ├── hive_service.dart  # Hive数据库服务
│   │   │   └── config_manager.dart # 配置管理器
│   │   └── bridge/                # 跨语言桥接
│   │       ├── platform_channel.dart
│   │       └── tun_controller.dart
│   ├── android/                   # Android特定代码
│   │   └── app/src/main/kotlin/
│   │       └── com/mihomo/flutter/
│   ├── ios/                       # iOS特定代码
│   │   └── Runner/
│   └── web/                       # Web支持
├── core/                          # 核心Go代码
│   └── bridge/
│       └── go_src/               # Go源码
│           ├── tun.go            # TUN实现
│           ├── config.go         # 配置解析
│           └── bridge.go         # 桥接接口
├── scripts/                       # 构建脚本
│   ├── build_all_platforms.sh    # 统一构建脚本
│   ├── test_*.sh                 # 测试脚本
│   └── verify_*.sh               # 验证脚本
├── docs/                         # 文档
│   ├── publishing/               # 发布文档
│   ├── por/                      # 项目路线图
│   └── api/                      # API文档
└── reference_code/               # 参考代码
```

## 核心组件详解

### 1. Flutter UI层

#### 主应用入口 (main.dart)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive数据库
  await Hive.initFlutter();

  // 注册类型适配器
  Hive.registerAdapter(ConfigDataAdapter());
  Hive.registerAdapter(ProxyServerAdapter());
  Hive.registerAdapter(StatisticsDataAdapter());

  runApp(const MihomoApp());
}
```

#### 主仪表板 (main_dashboard.dart)
- **实时流量监控**: 使用FlChart显示流量趋势
- **连接控制**: 一键连接/断开代理
- **服务器管理**: 显示当前服务器和切换选项
- **统计信息**: 流量使用和连接时长

#### 配置面板 (config_panel.dart)
- **YAML配置编辑**: 实时预览和验证
- **服务器管理**: 添加、编辑、删除服务器
- **规则配置**: 域名和IP规则管理
- **导入导出**: 配置文件管理

### 2. 桥接层

#### MethodChannel (Android/iOS)
```dart
class TunController {
  static const platform = MethodChannel('com.mihomo.flutter/tun');

  Future<bool> startTunnel(String config) async {
    try {
      return await platform.invokeMethod('startTunnel', {'config': config});
    } on PlatformException catch (e) {
      throw TunException('Failed to start tunnel: ${e.message}');
    }
  }
}
```

#### FFI (桌面端)
```dart
class TunController {
  static late final DynamicLibrary _library;

  static void initializeFFI() {
    _library = DynamicLibrary.open('libmihomo_core.so');
  }

  static int createTun() {
    return _library.lookup<NativeFunction<Int32 Function()>>('TunCreate').asFunction<int Function()>()();
  }
}
```

### 3. Go核心层

#### TUN实现 (tun.go)
```go
//export TunCreate
func TunCreate() int {
    // 创建TUN接口
    // 返回文件描述符
}

//export TunStart
func TunStart(config string) int {
    // 启动TUN服务
    // 返回状态码
}

//export TunReadPacket
func TunReadPacket(fd int, buffer unsafe.Pointer, length int) int {
    // 读取数据包
    // 返回读取的字节数
}
```

#### 配置解析 (config.go)
```go
// LoadConfigFile 加载YAML配置文件
func LoadConfigFile(path string) ([]byte, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, err
    }

    var config ConfigData
    err = yaml.Unmarshal(data, &config)
    return data, err
}
```

## 开发工作流

### 1. 功能开发
```bash
# 1. 创建功能分支
git checkout -b feature/new-feature

# 2. 开发功能
# 编辑相关文件...

# 3. 运行测试
flutter test
go test ./core/...

# 4. 构建验证
bash scripts/build_all_platforms.sh --android

# 5. 提交代码
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature
```

### 2. 调试方法

#### Flutter调试
```bash
# 启动调试模式
flutter run

# 热重载开发
flutter run --hot

# 分析性能
flutter run --profile

# 调试特定平台
flutter run -d android
flutter run -d ios
```

#### Go调试
```bash
# 编译Go代码
cd core/bridge/go_src
go build -o libmihomo_core.so

# 运行Go测试
go test -v

# 性能分析
go test -cpuprofile=cpu.prof -memprofile=mem.prof
```

### 3. 代码规范

#### Dart代码规范
```dart
// 使用dart analyze检查
dart analyze

// 使用dart format格式化
dart format .

// 使用flutter_lints规则
flutter analyze
```

#### Go代码规范
```bash
# 使用gofmt格式化
gofmt -w .

# 使用golint检查
golint ./...

# 使用go vet检查
go vet ./...
```

## 测试策略

### 1. 单元测试
```bash
# Flutter单元测试
flutter test

# Go单元测试
go test ./core/...
```

### 2. 集成测试
```bash
# 运行集成测试
bash scripts/test_t003_s4_simple.sh

# 特定功能测试
bash scripts/test_config_parser.sh
```

### 3. 跨平台测试
```bash
# 构建所有平台并测试
bash scripts/build_all_platforms.sh --all

# 运行平台特定测试
flutter test integration_test/
```

## 性能优化

### 1. Flutter性能
- **Widget重建优化**: 使用const构造函数
- **图片缓存**: 合理配置图片缓存策略
- **内存管理**: 及时释放资源

### 2. Go性能
- **并发处理**: 使用goroutine处理并发
- **内存池**: 重用内存缓冲区
- **零拷贝**: 减少数据复制

### 3. 跨语言性能
- **批量操作**: 减少跨语言调用次数
- **数据序列化**: 使用高效的序列化格式
- **缓存策略**: 缓存频繁访问的数据

## 安全考虑

### 1. 数据安全
- **本地加密**: 使用AES加密存储敏感数据
- **内存保护**: 及时清理敏感内存
- **权限最小化**: 只请求必要的系统权限

### 2. 网络安全
- **TLS验证**: 验证服务器证书
- **DNS安全**: 使用安全的DNS服务器
- **流量混淆**: 避免流量特征检测

### 3. 代码安全
- **输入验证**: 验证所有外部输入
- **错误处理**: 避免敏感信息泄露
- **代码审计**: 定期进行安全审计

## 部署和发布

### 1. 构建发布版本
```bash
# 构建所有平台
bash scripts/build_all_platforms.sh --all

# 或构建特定平台
bash scripts/build_all_platforms.sh --android --ios
```

### 2. 代码签名
```bash
# Android签名
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore release.keystore app-release.apk alias_name

# iOS签名 (Xcode)
# 在Xcode中配置签名证书和provisioning profile
```

### 3. 应用商店发布
详细流程请参考 [发布指南](PUBLISHING_GUIDE.md)

## 故障排除

### 常见开发问题

#### Flutter相关
```bash
# 清理Flutter缓存
flutter clean
flutter pub get

# 重置Flutter
flutter doctor -v
flutter config --clear-ios-signing-cert
```

#### 跨语言桥接问题
```bash
# 重新生成绑定
flutter packages pub run build_runner build

# 检查符号表
nm -g libmihomo_core.so | grep Tun
```

#### Go编译问题
```bash
# 清理Go缓存
go clean -cache

# 重新编译
go build -v ./core/...
```

### 性能问题诊断
```bash
# Flutter性能分析
flutter run --profile
flutter run --trace-startup

# Go性能分析
go tool pprof cpu.prof
go tool pprof mem.prof
```

## API参考

### 跨语言接口

#### TunController (Dart)
```dart
class TunController {
  // 创建TUN接口
  static Future<int> createTun();

  // 启动TUN服务
  static Future<bool> startTunnel(String config);

  // 停止TUN服务
  static Future<bool> stopTunnel();

  // 读取数据包
  static Future<List<int>> readPacket(int fd);

  // 写入数据包
  static Future<int> writePacket(int fd, List<int> data);
}
```

#### ConfigManager (Dart)
```dart
class ConfigManager {
  // 加载配置文件
  static Future<Map<String, dynamic>> loadConfig(String path);

  // 保存配置文件
  static Future<bool> saveConfig(Map<String, dynamic> config, String path);

  // 获取配置值
  static Future<dynamic> getConfigValue(String key);

  // 设置配置值
  static Future<bool> setConfigValue(String key, dynamic value);
}
```

#### Go接口
```go
// TUN相关函数
//export TunCreate
func TunCreate() int

//export TunStart
func TunStart(config string) int

//export TunStop
func TunStop() int

// 配置相关函数
//export LoadConfigFile
func LoadConfigFile(path string) *C.char

//export SaveConfigFile
func SaveConfigFile(path string, data *C.char) int
```

## 贡献指南

### 1. 代码贡献
1. Fork项目
2. 创建功能分支
3. 编写代码和测试
4. 提交Pull Request
5. 代码审查和合并

### 2. 问题报告
使用GitHub Issues模板：
- 详细描述问题
- 提供复现步骤
- 包含系统信息
- 附上相关日志

### 3. 功能请求
- 详细描述功能需求
- 说明使用场景
- 提供设计方案
- 考虑实现复杂度

---

**开发者支持**: dev@yourdomain.com
**文档更新**: 2025-12-07
**API版本**: v1.0.0