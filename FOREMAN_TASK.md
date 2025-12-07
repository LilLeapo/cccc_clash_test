# Foreman 监工任务

## 1. 环境与编译完整性检查 (高优先级)
由于项目涉及交叉编译，每次 Review 代码时必须检查：
- [ ] **Android**: `gomobile bind` 配置是否兼容当前的 `build.gradle`。
- [ ] **iOS**: `ClashCore.xcframework` 链接是否正常，Extension 的 Bundle ID 是否匹配。
- [ ] **Desktop**: CMake/Makefile 是否正确生成了 `.dll`/`.dylib`，且符号表 (Symbol Table) 导出了必要的 C 函数。
- [ ] **FFI Bindings**: 运行 `ffigen` 检查生成的 Dart 绑定是否与 C 头文件同步。

## 2. 架构一致性检查
- 检查 `core/bridge` 目录：是否混淆了 Mobile 和 Desktop 的逻辑？(应通过文件后缀或 tag 隔离)。
- 检查 UI 代码：是否出现了 `Platform.isIOS` 导致的大段 UI 分裂？(应尽量复用组件，仅在交互层微调)。

## 3. 引用参考
- 当遇到 TUN 读写瓶颈时，主动建议 Peer 查阅 `hiddify-app` 或 `clash_lib` 的相关实现。

## 4. 自动化维护
- 每次修改 Go 导出的结构体后，提醒 Peer 更新 C 头文件和 Dart 数据模型。
