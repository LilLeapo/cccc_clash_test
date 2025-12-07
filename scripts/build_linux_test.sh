#!/bin/bash

# Linux本地编译脚本 (测试用)
# 只编译当前平台的动态库

set -e

echo "🐧 开始Linux本地编译..."

# 设置环境变量
export PATH=~/go/bin:$PATH
export CGO_ENABLED=1

# 编译目录
CORE_DIR="."
BUILD_DIR="libs"
OUTPUT_DIR="$BUILD_DIR/desktop"

# 清理输出目录
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "📦 编译 Linux (AMD64)..."
go build \
    -buildmode=c-shared \
    -o "$OUTPUT_DIR/mihomo_core_linux_amd64.so" \
    -ldflags="-s" \
    "$CORE_DIR"

# 复制头文件
cp "$OUTPUT_DIR"/*.h "$BUILD_DIR/" 2>/dev/null || echo "⚠️  未找到头文件"

echo "✅ Linux编译完成!"
echo "📁 输出位置: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"