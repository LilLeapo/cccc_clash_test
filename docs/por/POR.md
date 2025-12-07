# POR — 计划记录 (Plan of Record)

## 北极星
构建最稳定、性能最好的跨平台 Mihomo 图形客户端。

## 护栏
- **不因为 UI 阻塞内核**: 内核必须能在 Headless 模式下独立运行测试。
- **不重造轮子**: 遇到复杂的 TUN 包处理，优先使用 gVisor/Mihomo 现成实现，不自己写 TCP/IP 栈。

## 路线图 (Roadmap)

### M1: 骨架与桥接 (当前阶段)
- [ ] 建立 Flutter + Go Module 混合项目结构。
- [ ] 实现 `core/bridge` 基础架构：Mobile (Gomobile) vs Desktop (FFI) 的抽象层。
- [ ] **Milestone Check**: 四端均能编译通过，并在 Dart 侧打印出 Go 内核版本号。

### M2: 核心生命周期
- [ ] Go 侧实现 `Start`, `Stop`, `Reload` 接口。
- [ ] 移动端后台保活机制 (Android Service / iOS NetworkExtension)。
- [ ] 实现日志回调：Go Log -> Bridge -> Dart UI Stream。

### M3: 流量接管 (The Hard Part)
- [ ] **Android**: 实现 VpnService -> fd -> Go gVisor。
- [ ] **iOS**: 实现 NEPacketTunnelProvider -> packetFlow -> Go gVisor。
- [ ] **Desktop**: 集成 Wintun / System Extension。

### M4: 配置与持久化
- [ ] Go 侧 YAML 解析器封装。
- [ ] Dart 侧 Hive 数据库搭建。
- [ ] UI 渲染配置面板。

### M5: UI 完善与发布
- [ ] Material 3 统一设计实现。
- [ ] 仪表盘 (Dashboard) 流量可视化。

## 风险与缓解
- **风险**: iOS 内存限制 (15MB/50MB 限制)。
  - **缓解**: 严格控制 Go GC 频率，使用 unsafe 指针减少数据包拷贝。
- **风险**: 交叉编译环境地狱。
  - **缓解**: 尽早编写 Dockerfile 或详细的 setup 脚本固定编译环境。
