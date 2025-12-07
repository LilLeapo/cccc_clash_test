# Mihomo Flutter Cross 发布指南

## 项目概览

**Mihomo Flutter Cross** 是一个跨平台代理客户端，支持Android、iOS、Windows、macOS和Linux平台。基于Flutter + Go + C混合架构，提供高性能的TUN模式代理功能。

### 核心特性
- 跨平台TUN流量接管 (Android VpnService + iOS NEPacketTunnelProvider)
- Material 3设计界面，实时流量可视化
- Go YAML配置解析 + Hive数据库持久化存储
- 跨语言桥接 (MethodChannel/FFI)
- 内存安全协议和零拷贝数据处理

## 版本信息

- **当前版本**: 0.1.0-alpha
- **包名**: com.mihomo.flutter
- **Bundle ID**: com.mihomo.flutter (统一所有平台)
- **目标SDK**: Android 14+, iOS 12.0+

## 构建环境要求

### 系统要求
- **操作系统**: macOS 12+ / Ubuntu 20.04+ / Windows 10+
- **内存**: 8GB+ (推荐16GB)
- **存储**: 20GB+ 可用空间

### 开发工具
- **Flutter SDK**: 3.24.0+
- **Dart SDK**: 3.5.0+
- **Go**: 1.21+
- **Android Studio**: 2023.1.1+
- **Xcode**: 15.0+ (macOS only)
- **Visual Studio**: 2022+ (Windows only)

## 快速开始

### 1. 环境配置
```bash
# 克隆项目
git clone <repository-url>
cd clash_cccc

# 检查Flutter环境
flutter doctor

# 安装依赖
cd flutter_app
flutter pub get
```

### 2. 构建所有平台
```bash
# 返回项目根目录
cd ../

# 执行统一构建脚本
bash scripts/build_all_platforms.sh --all
```

### 3. 构建特定平台
```bash
# 仅构建Android
bash scripts/build_all_platforms.sh --android

# 构建Android和iOS
bash scripts/build_all_platforms.sh --android --ios

# 构建桌面端
bash scripts/build_all_platforms.sh --windows --macos --linux
```

## 详细构建说明

### Android构建
```bash
# 构建AAB (用于Google Play)
flutter build appbundle \
    --release \
    --target-platform android-arm64,android-arm \
    --build-number=1 \
    --build-name=0.1.0-alpha

# 构建APK (用于直接安装)
flutter build apk \
    --release \
    --target-platform android-arm64,android-arm \
    --build-number=1 \
    --build-name=0.1.0-alpha
```

**输出位置**:
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

### iOS构建 (macOS only)
```bash
# 构建iOS应用
flutter build ios \
    --release \
    --build-number=1 \
    --build-name=0.1.0-alpha \
    --no-codesign

# 使用Xcode打开并签名
open ios/Runner.xcworkspace
```

**输出位置**: `build/ios/iphoneos/`

### Windows构建
```bash
# 启用Windows桌面支持
flutter config --enable-windows-desktop

# 构建Windows应用
flutter build windows \
    --release \
    --build-number=1 \
    --build-name=0.1.0-alpha
```

**输出位置**: `build/windows/x64/runner/Release/`

### macOS构建 (macOS only)
```bash
# 启用macOS桌面支持
flutter config --enable-macos-desktop

# 构建macOS应用
flutter build macos \
    --release \
    --build-number=1 \
    --build-name=0.1.0-alpha
```

**输出位置**: `build/macos/Build/Products/Release/mihomo_flutter_cross.app`

### Linux构建
```bash
# 启用Linux桌面支持
flutter config --enable-linux-desktop

# 安装Linux依赖
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev

# 构建Linux应用
flutter build linux \
    --release \
    --build-number=1 \
    --build-name=0.1.0-alpha
```

**输出位置**: `build/linux/x64/release/bundle/`

## 发布流程

### 1. Android发布

#### Google Play Console
1. **准备AAB文件**
   ```bash
   bash scripts/build_all_platforms.sh --android
   ```

2. **上传到Play Console**
   - 登录 [Google Play Console](https://play.google.com/console)
   - 创建新应用或选择现有应用
   - 上传 `release/app-release.aab`
   - 填写应用信息、截图、描述等

3. **隐私政策**
   - 应用需要VPN权限，需提供隐私政策URL
   - 说明数据收集、使用和共享方式

4. **审核流程**
   - 通常需要1-3天
   - 可能要求额外信息或修改

#### 直接分发APK
1. **构建APK**
   ```bash
   bash scripts/build_all_platforms.sh --android
   ```

2. **签名APK** (如果需要)
   ```bash
   # 生成签名密钥
   keytool -genkey -v -keystore ~/mihomo-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mihomo

   # 签名APK
   jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore ~/mihomo-upload-key.jks app-release.apk mihomo
   ```

### 2. iOS发布

#### App Store Connect
1. **构建应用**
   ```bash
   bash scripts/build_all_platforms.sh --ios
   ```

2. **使用Xcode上传**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - 选择 "Any iOS Device"
   - Product > Archive
   - 使用Xcode Organizer上传到App Store Connect

3. **TestFlight测试**
   - 在App Store Connect中创建TestFlight版本
   - 添加内部和外部测试员
   - 等待Beta审核

4. **正式发布**
   - 提交App Store审核
   - 审核时间通常1-7天

#### 企业分发
1. **配置企业证书**
2. **构建企业版**
3. **分发IPA文件**

### 3. 桌面端发布

#### Windows
1. **Microsoft Store**
   - 使用Windows App Cert Kit测试
   - 上传到Partner Center
   - 等待审核

2. **直接分发**
   - 打包为MSI或ZIP
   - 提供安装程序

#### macOS
1. **Mac App Store**
   - 使用Xcode公证
   - 上传到Mac App Store

2. **直接分发**
   - 打包为DMG
   - 代码签名和公证

#### Linux
1. **软件包格式**
   - AppImage (通用)
   - DEB (Debian/Ubuntu)
   - RPM (Red Hat/CentOS)
   - Snap包

2. **分发渠道**
   - GitHub Releases
   - Linux软件仓库
   - Flathub (Flatpak)

## 构建产物说明

### 文件结构
```
release/
├── app-release.aab          # Android App Bundle
├── app-release.apk          # Android APK
├── ios-app/                 # iOS应用包
├── windows-app/             # Windows应用
├── macos-app/               # macOS应用
├── linux-app/               # Linux应用
├── version.txt              # 版本信息
├── build_report.md          # 构建报告
└── Mihomo_Flutter_Cross-0.1.0-alpha-release.tar.gz  # 发布包
```

### 版本号规则
- **格式**: MAJOR.MINOR.PATCH
- **示例**: 0.1.0-alpha
- **构建编号**: 递增数字

## 故障排除

### 常见构建问题

#### Flutter相关
```bash
# 清理Flutter缓存
flutter clean
flutter pub get
flutter doctor -v

# 重新安装依赖
rm -rf .packages pubspec.lock
flutter pub get
```

#### Android相关
```bash
# 检查Android SDK
flutter doctor --android-licenses

# 重新配置Android
flutter config --android-studio-dir /path/to/android-studio
```

#### iOS相关
```bash
# 更新CocoaPods
cd ios
pod repo update
pod install

# 重置iOS构建
rm -rf ios/.symlinks
flutter clean
cd ios && pod install && cd ..
flutter build ios
```

#### 桌面端相关
```bash
# 启用桌面支持
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# 重新安装桌面依赖
flutter clean
flutter pub get
```

### 性能优化

#### 构建优化
```bash
# 启用并行构建
flutter build apk --split-per-abi

# 启用代码压缩
flutter build apk --split-debug-info=/path/to/symbols

# 移除调试信息
flutter build apk --obfuscate --split-debug-info=/path/to/symbols
```

#### 包大小优化
```bash
# 分析包大小
flutter build apk --analyze-size

# 移除未使用的资源
flutter build apk --tree-shake-icons
```

## 测试验证

### 自动化测试
```bash
# 运行单元测试
flutter test

# 运行集成测试
flutter test integration_test/

# 运行特定平台测试
flutter test integration_test/ --device-id=<device-id>
```

### 手动测试清单
- [ ] 应用启动和界面显示正常
- [ ] 配置文件导入导出功能
- [ ] TUN模式启动和停止
- [ ] 流量统计实时更新
- [ ] 设置保存和恢复
- [ ] 错误处理和日志记录
- [ ] 内存使用在限制范围内
- [ ] 电池续航影响测试

## 发布检查清单

### 发布前检查
- [ ] 所有功能测试通过
- [ ] 性能基准测试达标
- [ ] 内存泄漏检测通过
- [ ] 安全性扫描完成
- [ ] 文档和帮助信息完整
- [ ] 隐私政策已准备
- [ ] 应用商店元数据准备

### 构建验证
- [ ] 所有平台构建成功
- [ ] 发布包大小合理
- [ ] 版本号和构建编号正确
- [ ] 代码签名和公证完成
- [ ] 构建报告生成成功

### 发布后验证
- [ ] 应用商店状态正常
- [ ] 下载和安装测试
- [ ] 核心功能验证
- [ ] 崩溃报告监控
- [ ] 用户反馈收集

## 联系和支持

- **问题反馈**: [GitHub Issues](https://github.com/your-repo/issues)
- **功能请求**: [GitHub Discussions](https://github.com/your-repo/discussions)
- **安全漏洞**: security@yourdomain.com

## 许可证

本项目采用MIT许可证，详见LICENSE文件。

---

**最后更新**: 2025-12-07
**文档版本**: 1.0.0