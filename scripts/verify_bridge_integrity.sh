#!/bin/bash

# T001 Bridge层完整性验证脚本
# 验证构建脚本、目录结构和代码完整性

set -e

echo "🔍 T001 Bridge层完整性验证..."

# 验证目录结构
echo "📁 检查目录结构..."
REQUIRED_DIRS=(
    "core/bridge/go_src"
    "core/bridge/c_src"
    "scripts"
    "flutter_app/lib"
    "libs"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir"
    else
        echo "  ❌ $dir 缺失"
        exit 1
    fi
done

# 验证核心文件
echo "📄 检查核心文件..."
REQUIRED_FILES=(
    "core/bridge/go_src/bridge.go"
    "core/bridge/go_src/go.mod"
    "core/bridge/c_src/bridge.h"
    "core/bridge/c_src/bridge.c"
    "core/bridge/c_src/CMakeLists.txt"
    "scripts/build_core_desktop.sh"
    "scripts/build_core_mobile.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file 缺失"
        exit 1
    fi
done

# 验证构建脚本指向正确目录
echo "🔧 验证构建脚本配置..."

DESKTOP_CORE_DIR=$(grep "^CORE_DIR=" scripts/build_core_desktop.sh | cut -d'"' -f2)
MOBILE_CORE_DIR=$(grep "^CORE_DIR=" scripts/build_core_mobile.sh | cut -d'"' -f2)

if [ "$DESKTOP_CORE_DIR" = "core/bridge/go_src" ]; then
    echo "  ✅ Desktop构建脚本指向正确目录"
else
    echo "  ❌ Desktop构建脚本目录错误: $DESKTOP_CORE_DIR"
    exit 1
fi

if [ "$MOBILE_CORE_DIR" = "core/bridge/go_src" ]; then
    echo "  ✅ Mobile构建脚本指向正确目录"
else
    echo "  ❌ Mobile构建脚本目录错误: $MOBILE_CORE_DIR"
    exit 1
fi

# 验证Go代码导出函数
echo "🔍 检查Go导出函数..."
if grep -q "//export InitializeCore" core/bridge/go_src/bridge.go; then
    echo "  ✅ InitializeCore 导出函数存在"
else
    echo "  ❌ InitializeCore 导出函数缺失"
    exit 1
fi

if grep -q "//export StartMihomoProxy" core/bridge/go_src/bridge.go; then
    echo "  ✅ StartMihomoProxy 导出函数存在"
else
    echo "  ❌ StartMihomoProxy 导出函数缺失"
    exit 1
fi

if grep -q "//export TunCreate" core/bridge/go_src/bridge.go; then
    echo "  ✅ TUN相关导出函数存在"
else
    echo "  ❌ TUN相关导出函数缺失"
    exit 1
fi

# 验证C头文件接口
echo "🔍 检查C头文件接口..."
if grep -q "int32_t InitializeCore" core/bridge/c_src/bridge.h; then
    echo "  ✅ C InitializeCore 接口存在"
else
    echo "  ❌ C InitializeCore 接口缺失"
    exit 1
fi

if grep -q "int32_t TunCreate" core/bridge/c_src/bridge.h; then
    echo "  ✅ C TUN接口存在"
else
    echo "  ❌ C TUN接口缺失"
    exit 1
fi

# 验证Flutter桥接层
echo "📱 检查Flutter桥接层..."
if [ -f "flutter_app/lib/mihomo_core.dart" ]; then
    echo "  ✅ Flutter核心桥接类存在"
else
    echo "  ❌ Flutter核心桥接类缺失"
    exit 1
fi

if [ -f "flutter_app/lib/platform/desktop/ffi_bridge.dart" ]; then
    echo "  ✅ FFI桥接实现存在"
else
    echo "  ❌ FFI桥接实现缺失"
    exit 1
fi

echo ""
echo "🎉 T001 Bridge层完整性验证通过！"
echo ""
echo "📊 验证摘要:"
echo "  - 目录结构: ✅ 完整"
echo "  - 核心文件: ✅ 完整"
echo "  - 构建脚本: ✅ 配置正确"
echo "  - Go导出: ✅ 函数完整"
echo "  - C接口: ✅ 接口完整"
echo "  - Flutter桥接: ✅ 准备就绪"
echo ""
echo "🚀 项目现在可以进行:"
echo "  1. gomobile bind 编译测试 (需要Go环境)"
echo "  2. CGO编译测试 (需要Go+ GCC环境)"
echo "  3. Flutter集成测试"
echo "  4. 跨平台构建验证"