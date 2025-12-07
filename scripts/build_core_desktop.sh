#!/bin/bash

# Desktop跨平台编译脚本 (Windows/macOS/Linux)
# 使用 go build -buildmode=c-shared 生成 .dll/.dylib/.so 和 .h 文件

set -e

echo "🚀 开始 Desktop 端核心编译..."

# 设置环境变量
export PATH=~/go/bin:$PATH
export CGO_ENABLED=1

# 编译目录
CORE_DIR="core/bridge/go_src"
BUILD_DIR="libs"
OUTPUT_DIR="$BUILD_DIR/desktop"

# 切换到核心目录
cd "$CORE_DIR"

# 清理输出目录
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "📦 编译 Linux (AMD64) - 测试用..."
GOOS=linux GOARCH=amd64 go build \
    -buildmode=c-shared \
    -o "libs/desktop/mihomo_core_linux_amd64.so" \
    -ldflags="-s" \
    .

echo "📦 编译 Windows (AMD64)..."
GOOS=windows GOARCH=amd64 go build \
    -buildmode=c-shared \
    -o "libs/desktop/mihomo_core_windows_amd64.dll" \
    -ldflags="-s" \
    .

echo "📦 编译 macOS (AMD64)..."
GOOS=darwin GOARCH=amd64 go build \
    -buildmode=c-shared \
    -o "libs/desktop/mihomo_core_darwin_amd64.dylib" \
    -ldflags="-s" \
    .

echo "📦 编译 macOS (ARM64)..."
GOOS=darwin GOARCH=arm64 go build \
    -buildmode=c-shared \
    -o "libs/desktop/mihomo_core_darwin_arm64.dylib" \
    -ldflags="-s" \
    .

# 复制头文件
cp libs/desktop/*.h "../libs/" 2>/dev/null || echo "⚠️  未找到头文件"

echo "✅ Desktop 端编译完成!"
echo "📁 输出位置: $(pwd)/$OUTPUT_DIR"
ls -la "$OUTPUT_DIR"