# Mihomo Flutter Cross 发布指南

## 发布概览
- **应用名称**: Mihomo Flutter Cross
- **应用标识符**: com.mihomo.flutter
- **版本**: v0.1.0-alpha
- **发布状态**: Alpha测试版

## 📱 Android平台发布

### 应用商店信息
- **包名**: com.mihomo.flutter
- **版本号**: 1
- **版本名称**: 0.1.0-alpha
- **最小SDK**: API 24 (Android 7.0)
- **目标SDK**: API 34 (Android 14)

### 权限配置
```xml
<!-- 必需的VPN权限 -->
<uses-permission android:name="android.permission.BIND_VPN_SERVICE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- 网络权限 -->
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

### 构建脚本
```bash
#!/bin/bash
# 构建Android发布版

echo "🚀 开始构建Android发布版..."

# 清理构建缓存
cd flutter_app
flutter clean
flutter pub get

# 构建AAB格式 (Google Play推荐)
flutter build appbundle \
  --release \
  --target-platform android-arm64,android-arm \
  --build-number=1 \
  --build-name=0.1.0-alpha

# 构建APK格式 (备用)
flutter build apk \
  --release \
  --target-platform android-arm64,android-arm \
  --build-number=1 \
  --build-name=0.1.0-alpha

echo "✅ Android构建完成"
echo "📍 AAB文件: build/app/outputs/bundle/release/app-release.aab"
echo "📍 APK文件: build/app/outputs/flutter-apk/app-release.apk"
```

## 🍎 iOS平台发布

### Bundle ID配置
- **Bundle Identifier**: com.mihomo.flutter
- **Team ID**: [需要配置开发者团队ID]
- **Provisioning Profile**: [需要开发者证书]

### 应用权限
```xml
<!-- Info.plist -->
<key>NSDocumentsFolderUsageDescription</key>
<string>应用需要访问文档文件夹来存储配置文件</string>

<key>NSSystemConfigurationUsageDescription</key>
<string>应用需要网络配置权限来提供代理服务</string>

<key>NSNetworkVolumesUsageDescription</key>
<string>应用需要访问网络卷来设置VPN连接</string>

<key>NSAppleEventsUsageDescription</key>
<string>应用需要Apple Events权限来管理网络代理</string>
```

### Network Extension权限
```xml
<!-- 在VPN权限文件中 -->
<key>com.apple.developer.networking.networkextension</key>
<true/>
<key>com.apple.developer.networking.vpn.api</key>
<array>
    <string>allow-vpn</string>
</array>
```

### 构建脚本
```bash
#!/bin/bash
# 构建iOS发布版

echo "🍎 开始构建iOS发布版..."

cd flutter_app

# 清理构建缓存
flutter clean
flutter pub get

# 构建iOS
flutter build ios \
  --release \
  --build-number=1 \
  --build-name=0.1.0-alpha

# 使用Xcode构建 (推荐)
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath Runner.xcarchive \
  archive

# 导出IPA
xcodebuild -exportArchive \
  -archivePath Runner.xcarchive \
  -exportPath export \
  -exportOptionsPlist ExportOptions.plist

echo "✅ iOS构建完成"
echo "📍 IPA文件: export/Runner.ipa"
```

## 💻 桌面端发布

### Windows构建
```bash
#!/bin/bash
# 构建Windows发布版

echo "🪟 开始构建Windows发布版..."

cd flutter_app

# 添加Windows桌面支持
flutter config --enable-windows-desktop

# 构建Windows
flutter build windows \
  --release \
  --build-number=1 \
  --build-name=0.1.0-alpha

# 使用NSIS创建安装包
cd windows
packaging/windows/msix/PackagingWindows.targets build

echo "✅ Windows构建完成"
echo "📍 可执行文件: build/windows/x64/runner/Release/mihomo_flutter_cross.exe"
echo "📍 MSIX包: build/windows/x64/runner/Release/MihomoFlutterCross_0.1.0-alpha_Test/msix/mihomo_flutter_cross.msix"
```

### macOS构建
```bash
#!/bin/bash
# 构建macOS发布版

echo "🍎 开始构建macOS发布版..."

cd flutter_app

# 添加macOS桌面支持
flutter config --enable-macos-desktop

# 构建macOS
flutter build macos \
  --release \
  --build-number=1 \
  --build-name=0.1.0-alpha

# 使用create-dmg创建DMG安装包
cd build/macos/Build/Products/Release
hdiutil create -volname "Mihomo Flutter Cross" -srcfolder . -ov -format UDZO "MihomoFlutterCross-0.1.0-alpha.dmg"

echo "✅ macOS构建完成"
echo "📍 应用包: build/macos/Build/Products/Release/mihomo_flutter_cross.app"
echo "📍 DMG文件: build/macos/Build/Products/Release/MihomoFlutterCross-0.1.0-alpha.dmg"
```

## 📦 发布准备清单

### ✅ 必需材料
- [ ] 应用图标 (多尺寸)
- [ ] 应用截图 (Android/iOS/Desktop)
- [ ] 应用描述和功能介绍
- [ ] 隐私政策
- [ ] 用户协议
- [ ] 应用分类和关键词
- [ ] 开发者账户设置

### ✅ 技术要求
- [ ] 崩溃日志收集 (Firebase Crashlytics)
- [ ] 性能监控 (Firebase Performance)
- [ ] 应用分析 (Firebase Analytics)
- [ ] 用户反馈系统
- [ ] 错误报告机制
- [ ] 版本更新机制

### ✅ 法律合规
- [ ] 隐私政策文档
- [ ] 用户使用协议
- [ ] 数据收集声明
- [ ] 第三方库许可证
- [ ] 安全审计报告

## 🎨 应用商店素材

### 应用图标规格
```
Android:
- 512x512 (高分辨率)
- 192x192 (中分辨率)
- 48x48 (低分辨率)

iOS:
- 1024x1024 (App Store)
- 180x180 (iPhone 6 Plus)
- 120x120 (iPhone)
- 76x76 (iPad)

Desktop:
- 256x256 (Windows)
- 512x512 (macOS)
- 64x64 (Linux)
```

### 应用截图规格
```
Android (Google Play):
- 手机: 16:9 或 9:16, 最小320dp
- 平板: 16:10 或 10:16, 最小1024dp

iOS (App Store):
- iPhone: 1125x2436 (iPhone X/11/12/13/14/15)
- iPad: 2224x1668 (iPad标准) 或 2388x1668 (iPad Pro)

Desktop:
- Windows: 1280x720
- macOS: 1440x900
- Linux: 1366x768
```

## 📋 版本管理

### 语义化版本
- **主版本** (X.0.0): 不兼容的API变更
- **次版本** (x.Y.0): 向后兼容的功能性新增
- **修订版本** (x.y.Z): 向后兼容的问题修正

### 当前版本策略
```
当前: 0.1.0-alpha
- 0: 主版本 (未稳定)
- 1: 次版本 (初次功能集)
- 0: 修订版本 (首次发布)

后续版本:
- 0.1.1-alpha: 问题修复
- 0.2.0-alpha: 新功能添加
- 1.0.0: 正式稳定版
```

## 🔧 自动化发布

### GitHub Actions CI/CD
```yaml
# .github/workflows/release.yml
name: Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Build Android
        run: |
          cd flutter_app
          flutter build appbundle --release

      - name: Upload to Play Console
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.mihomo.flutter
          releaseFiles: flutter_app/build/app/outputs/bundle/release/app-release.aab
          track: alpha

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Build iOS
        run: |
          cd flutter_app
          flutter build ios --release --no-codesign

      - name: Upload to App Store
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: |
          # 上传到App Store Connect
```

## 📊 发布后监控

### 关键指标
- [ ] 应用下载量
- [ ] 用户留存率
- [ ] 崩溃率 (< 1%)
- [ ] 平均评分 (目标 > 4.0)
- [ ] 用户反馈数量
- [ ] 网络连接成功率

### 监控工具
- **Firebase Crashlytics**: 崩溃监控
- **Firebase Performance**: 性能监控
- **Firebase Analytics**: 用户行为分析
- **Google Play Console**: Android平台数据
- **App Store Connect**: iOS平台数据

## 🚀 发布时间表

### Alpha版本 (当前)
- [ ] 完成内部测试
- [ ] 修复关键问题
- [ ] 准备发布资料

### Beta版本 (下一个)
- [ ] 邀请测试用户
- [ ] 收集用户反馈
- [ ] 优化用户体验

### 正式版本 (最终)
- [ ] 性能优化
- [ ] 完善文档
- [ ] 正式发布

---

**发布负责人**: MiniMax-M2
**最后更新**: 2025-12-07
**版本**: v0.1.0-alpha