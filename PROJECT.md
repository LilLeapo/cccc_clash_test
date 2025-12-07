# 项目定义: Mihomo-Flutter-Cross (Next-Gen Clash Client)

## 1. 项目愿景
构建一个基于 **Clash Meta (Mihomo)** 内核的下一代跨平台代理工具。
- **核心目标**: 全平台 (Android, iOS, Windows, macOS) 统一体验，高性能 TUN 模式。
- **参考项目**: Hiddify-App, FlClash, ClashX, ClashMi (请积极参考这些源码中的实现细节)。

## 2. 技术栈架构 (严格遵守)
### 前端层 (UI)
- **框架**: Flutter (Dart)
- **设计**: 统一的高定版 Material 3 (Brand-First)，不做两套 UI。
- **交互**: 仅在滑动返回、触感反馈等细节上做平台级适配。

### 桥接层 (The Bridge)
**核心目录**: `core/bridge/`
由于移动端和桌面端构建方式不同，必须实现 **Interface Adapter** 模式：
- **Android/iOS**: 使用 `gomobile` (Dart -> MethodChannel -> Native(Kt/Swift) -> Go)。
- **Windows/macOS**: 使用 `cgo/FFI` (Dart -> FFI -> C Dynamic Lib -> Go)。
- **数据流**:
  - 配置/控制流: JSON 传递。
  - 数据包流 (TUN): 必须零拷贝或最小拷贝。

### 内核层 (Go)
- **核心**: Mihomo (Clash Meta)
- **配置解析**: **Go 侧全权负责**。Dart 仅传递 config path，Go 解析并返回 JSON 供 UI 渲染。
- **TUN 实现**:
  - **Mobile**: Android (VpnService fd) / iOS (NEPacketTunnelProvider packets) -> **gVisor/Netstack** (Go User-space Stack)。
  - **Desktop**: Windows (Wintun) / macOS (System Extension)。

### 数据存储
- **轻量配置**: `shared_preferences` (需配置 App Group 以便主 App 和 VPN Extension 共享)。
- **复杂数据**: `hive` (日志、元数据)。
- **配置文件**: 直接文件系统存储 (App Group 共享目录)。

## 3. 关键开发规范
### 内存安全 (CGO/FFI)
1. **谁分配，谁释放**: C 侧申请的 `char*` 必须提供 C 侧的 `free_string` 函数暴露给 Dart。
2. **Keep Alive**: 在 FFI 异步调用期间，必须防止 Dart GC 回收 Go 指针。
3. **Panic Catching**: Go 侧必须 recover 所有 panic，转换成 error code 返回，绝对禁止让 Go panic 导致 App 崩溃。

### 编译与构建
- 这是一个 **四端编译** 项目。
- 所有的 C 胶水代码必须放在 `core/bridge/c_src`。
- 所有的 Go 导出代码必须放在 `core/bridge/go_src`。
- 使用 Conditional Compilation (`+build android`, `+build darwin`, etc.) 严格隔离平台代码。

## 4. 当前上下文
项目刚初始化。首要任务是搭建目录结构，并打通 "Dart -> Bridge -> Go" 的 Hello World 链路。
