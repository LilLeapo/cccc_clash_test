# POR — 计划记录 (Plan of Record)

## 北极星
构建最稳定、性能最好的跨平台 Mihomo 图形客户端。

## 护栏
- **不因为 UI 阻塞内核**: 内核必须能在 Headless 模式下独立运行测试。
- **不重造轮子**: 遇到复杂的 TUN 包处理，优先使用 gVisor/Mihomo 现成实现，不自己写 TCP/IP 栈。

## 路线图 (Roadmap)

### M1: 骨架与桥接 (已显著进展)
- [x] ✅ 建立 Flutter + Go Module 混合项目结构。
- [x] ✅ 实现 `core/bridge` 基础架构：Mobile (Gomobile) vs Desktop (FFI) 的抽象层。
- [x] ✅ **Milestone Check**: Linux端编译验证通过，成功生成1.9MB动态库，14个核心函数正确导出。

### M2: 核心生命周期 (已显著进展)
- [x] ✅ Go 侧实现 `Start`, `Stop`, `Reload` 接口。
- [x] ✅ 移动端后台保活机制 (Android Service / iOS NetworkExtension)。
- [x] ✅ 实现日志回调：Go Log -> Bridge -> Dart UI Stream。

### M3: 流量接管 (已完成)
- [x] ✅ **Android**: 实现 VpnService -> fd -> Go gVisor。
- [x] ✅ **iOS**: 实现 NEPacketTunnelProvider -> packetFlow -> Go gVisor。
- [ ] **Desktop**: 集成 Wintun / System Extension。

### M4: 配置与持久化
- [ ] Go 侧 YAML 解析器封装。
- [ ] Dart 侧 Hive 数据库搭建。
- [ ] UI 渲染配置面板。

### M5: UI 完善与发布
- [ ] Material 3 统一设计实现。
- [ ] 仪表盘 (Dashboard) 流量可视化。

## 当前进展 (Now/Next)

### Now - 当前活跃任务
- **T004: 配置管理实现** (active)
  - T004-S1: Go侧YAML配置文件解析器封装 (pending)
  - T004-S2: Dart侧Hive数据库集成 (pending)
  - T004-S3: UI配置面板开发 (pending)

### Next - 下一步计划
1. 完成T004-S1 YAML解析器实现
2. 集成Hive数据库存储
3. 开发配置管理UI界面

## 已验证成果
- **Bridge层架构**: core/bridge/go_src/ 和 c_src/ 完整实现
- **编译验证**: Linux动态库成功生成，14个导出函数可用
- **技术基础**: Go↔C↔Dart FFI完整链路建立
- **TUN模式实现**: Android VpnService + iOS NEPacketTunnelProvider + Go TUN接口全平台完成

## 风险与缓解
- **风险**: iOS 内存限制 (15MB/50MB 限制)。
  - **缓解**: 严格控制 Go GC 频率，使用 unsafe 指针减少数据包拷贝。
- **风险**: 交叉编译环境地狱。
  - **缓解**: 尽早编写 Dockerfile 或详细的 setup 脚本固定编译环境。
- **风险**: TUN流量处理复杂性。
  - **缓解**: 基于mihomo现有实现，避免自研TCP/IP栈。

## Aux Delegations - Meta-Review/Revise (strategic)
Strategic only: list meta-review/revise items offloaded to Aux.
Keep each item compact: what (one line), why (one line), optional acceptance.
Tactical Aux subtasks now live in each task.yaml under 'Aux (tactical)'; do not list them here.
After integrating Aux results, either remove the item or mark it done.
- [ ] <meta-review — why — acceptance(optional)>
- [ ] <revise — why — acceptance(optional)>
