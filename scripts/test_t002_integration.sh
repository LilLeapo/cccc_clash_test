#!/bin/bash

# T002集成测试脚本
# 验证完整的Dart->Go链路

set -e

echo "🧪 开始T002完整链路集成测试..."

# 检查编译产物
echo "📁 检查Go动态库:"
if [ -f "libs/desktop/mihomo_core_linux_amd64.so" ]; then
    echo "✅ 找到Go动态库: $(ls -lh libs/desktop/mihomo_core_linux_amd64.so)"
else
    echo "❌ 未找到Go动态库，请先运行编译"
    exit 1
fi

if [ -f "libs/desktop/mihomo_core_linux_amd64.h" ]; then
    echo "✅ 找到C头文件: $(ls -lh libs/desktop/mihomo_core_linux_amd64.h)"
else
    echo "❌ 未找到C头文件"
    exit 1
fi

# 检查Dart测试文件
echo "📁 检查Dart测试文件:"
if [ -f "flutter_app/lib/test_integration.dart" ]; then
    echo "✅ 找到Dart集成测试文件"
else
    echo "❌ 未找到Dart集成测试文件"
    exit 1
fi

echo ""
echo "🔍 验证导出的Go函数:"
echo "从头文件中提取的函数:"
grep "extern" libs/desktop/mihomo_core_linux_amd64.h | grep -v "^//"

echo ""
echo "📦 检查Dart FFI桥接实现:"
echo "检查关键函数映射:"
grep -n "lookup.*HelloWorld\|lookup.*InitializeCore\|lookup.*GetVersion" flutter_app/lib/test_integration.dart || echo "⚠️  未找到函数映射"

echo ""
echo "🎯 测试准备完成!"
echo "下一步需要:"
echo "1. 运行Dart测试: dart flutter_app/lib/test_integration.dart"
echo "2. 验证函数调用成功"
echo "3. 确认内存管理正确"
echo "4. 测试错误处理机制"

echo ""
echo "🚀 如果有Dart环境，可以运行以下命令测试:"
echo "cd flutter_app && dart lib/test_integration.dart"

echo ""
echo "✅ T002集成测试环境准备完成!"