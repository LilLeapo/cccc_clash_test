#!/bin/bash

# 基础构建验证脚本
# 验证构建系统本身是否工作正常

set -e

echo "🔧 验证构建系统基础功能..."

# 检查环境
echo "📍 检查工作目录:"
pwd
echo "📁 检查项目结构:"
ls -la

echo "📦 检查 Go 模块:"
export PATH=~/go/bin:$PATH
go version
go mod verify

echo "🏗️  测试本地编译 (非跨平台):"
go build -o test_binary main.go

echo "✅ 测试执行:"
./test_binary

echo "🧹 清理测试文件:"
rm test_binary

echo "🎉 基础构建系统验证完成!"
echo "📝 注意: 跨平台编译需要在相应的目标平台环境中进行"
echo "💡 当前在WSL环境中，需要安装Windows/macOS交叉编译工具链"