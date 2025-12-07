# Mihomo-Flutter-Cross 构建系统
# 支持跨平台编译的统一入口

.PHONY: help clean desktop mobile all test deps

# 默认目标
help:
	@echo "Mihomo-Flutter-Cross 构建系统"
	@echo ""
	@echo "可用命令:"
	@echo "  deps     - 安装构建依赖 (Go, gomobile等)"
	@echo "  desktop  - 编译 Desktop 端 (Windows/macOS)"
	@echo "  mobile   - 编译 Mobile 端 (Android/iOS)"
	@echo "  all      - 编译所有平台"
	@echo "  clean    - 清理构建输出"
	@echo "  test     - 运行测试"

# 设置环境变量
export PATH := $(HOME)/go/bin:$(PATH)
export CGO_ENABLED := 1

# 目录变量
CORE_DIR := .
BUILD_DIR := libs
SCRIPTS_DIR := scripts

# 安装构建依赖
deps:
	@echo "📦 检查 Go 环境..."
	@go version || (echo "❌ Go 未安装" && exit 1)
	@echo "📦 安装 gomobile..."
	@go install golang.org/x/mobile/cmd/gomobile@latest || true
	@go get golang.org/x/mobile/cmd/gobind || true
	@echo "✅ 依赖安装完成"

# Desktop 端编译
desktop:
	@echo "🚀 开始 Desktop 端编译..."
	@chmod +x $(SCRIPTS_DIR)/build_core_desktop.sh
	@$(SCRIPTS_DIR)/build_core_desktop.sh

# Mobile 端编译
mobile:
	@echo "🚀 开始 Mobile 端编译..."
	@chmod +x $(SCRIPTS_DIR)/build_core_mobile.sh
	@$(SCRIPTS_DIR)/build_core_mobile.sh

# 编译所有平台
all: deps desktop mobile
	@echo "🎉 所有平台编译完成!"

# 清理构建输出
clean:
	@echo "🧹 清理构建输出..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ 清理完成"

# 运行测试
test:
	@echo "🧪 运行测试..."
	@cd $(CORE_DIR) && go test -v ./...
	@echo "✅ 测试完成"

# 验证项目结构
verify:
	@echo "🔍 验证项目结构..."
	@test -f "go.mod" || (echo "❌ 缺少 go.mod 文件" && exit 1)
	@test -d "core/bridge" || (echo "❌ 缺少 core/bridge 目录" && exit 1)
	@test -d "core/bridge/c_src" || (echo "❌ 缺少 core/bridge/c_src 目录" && exit 1)
	@test -d "core/bridge/go_src" || (echo "❌ 缺少 core/bridge/go_src 目录" && exit 1)
	@echo "✅ 项目结构验证通过"

# 检查依赖是否完整
check-deps:
	@echo "🔍 检查依赖完整性..."
	@cd $(CORE_DIR) && go mod tidy
	@go list -m all | grep -q "github.com/metacubex/mihomo" || (echo "❌ mihomo 依赖缺失" && exit 1)
	@echo "✅ 依赖检查通过"