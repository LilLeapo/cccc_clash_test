#!/bin/bash

# Mobile跨平台编译脚本 (Android/iOS)
# 使用 gomobile bind 生成 .aar (Android) 和 .xcframework (iOS)

set -e

echo "🚀 开始 Mobile 端核心编译..."

# 设置环境变量
export PATH=~/go/bin:$PATH

# 编译目录
CORE_DIR="core/bridge/go_src"
BUILD_DIR="libs"
OUTPUT_DIR="$BUILD_DIR/mobile"

# 清理输出目录
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 检查 gomobile 是否安装
if ! command -v gomobile &> /dev/null; then
    echo "📦 安装 gomobile..."
    go install golang.org/x/mobile/cmd/gomobile@latest
    go get golang.org/x/mobile/cmd/gobind
fi

# 初始化 gomobile
echo "🔧 初始化 gomobile..."
gomobile init

echo "📦 编译 Android (ARM64)..."
gomobile bind \
    -target=android/arm64 \
    -o "$OUTPUT_DIR/mihomo_core_android_arm64.aar" \
    -javapkg=com.mihomoflutter.core \
    "$CORE_DIR"

echo "📦 编译 Android (ARM)..."
gomobile bind \
    -target=android/arm \
    -o "$OUTPUT_DIR/mihomo_core_android_arm.aar" \
    -javapkg=com.mihomoflutter.core \
    "$CORE_DIR"

echo "📦 编译 iOS (ARM64)..."
gomobile bind \
    -target=ios \
    -o "$OUTPUT_DIR/mihomo_core_ios.xcframework" \
    "$CORE_DIR"

echo "✅ Mobile 端编译完成!"
echo "📁 输出位置: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"