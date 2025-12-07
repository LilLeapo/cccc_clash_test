# Mihomo-Flutter-Cross 项目架构文档

## 目录结构

```
/mnt/c/Users/Administrator/clash_cccc/
├── flutter_app/                 # Flutter 前端应用
│   ├── lib/                    # Dart 源码
│   ├── android/app/            # Android 特定配置
│   ├── ios/Runner/             # iOS 特定配置
│   ├── windows/                # Windows 特定配置
│   └── macos/                  # macOS 特定配置
├── core/                       # 核心层（Go + 桥接层）
│   ├── bridge/                 # 桥接层（关键目录）
│   │   ├── c_src/             # C 胶水代码 (桌面端 FFI)
│   │   └── go_src/            # Go 导出代码 (移动端 gomobile)
│   └── go/                    # Go 源码 (Mihomo 内核)
├── scripts/                    # 构建脚本
│   ├── build_core_desktop.sh  # 桌面端构建脚本
│   └── build_core_mobile.sh   # 移动端构建脚本
├── libs/                       # 生成的库文件
│   ├── desktop/               # 桌面端库文件 (.dll, .dylib)
│   └── mobile/                # 移动端库文件
│       ├── android/           # Android AAR
│       └── ios/               # iOS XCFramework
└── .cccc/work/                # 工作目录
    ├── samples/               # 示例代码
    └── logs/                  # 构建日志
```

## 桥接层设计原则

### 核心目录: `core/bridge/`
- **Interface Adapter 模式**: 统一抽象，平台差异化实现
- **内存安全**: 严格遵循 CGO/FFI 内存管理规范
- **平台隔离**: 使用条件编译隔离平台代码

### 平台适配策略
- **Android/iOS**: gomobile (Dart -> MethodChannel -> Native(Kt/Swift) -> Go)
- **Windows/macOS**: cgo/FFI (Dart -> FFI -> C Dynamic Lib -> Go)

## 构建流程
1. **Desktop**: Go build -buildmode=c-shared -> C 动态库 -> Dart FFI
2. **Mobile**: gomobile bind -> 平台原生库 -> Dart MethodChannel

## 下一步计划
- S2: 初始化 Go Module 并引入 mihomo 依赖
- S3: 编写 Desktop 端构建脚本
- S4: 编写 Mobile 端构建脚本
- S5: 配置 Flutter 基础类