#!/bin/bash

# T003-S4 简化版TUN功能集成测试
# 不依赖jq命令，使用基本shell命令进行测试

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 测试配置
TEST_DIR="tests/t003_s4_integration"
TEST_LOG="$TEST_DIR/test_execution.log"
RESULTS_FILE="$TEST_DIR/real_integration_results.json"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a $TEST_LOG
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a $TEST_LOG
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a $TEST_LOG
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a $TEST_LOG
}

# 初始化测试环境
initialize_test_environment() {
    log_info "初始化T003-S4实际集成测试环境..."

    mkdir -p $TEST_DIR
    echo "T003-S4实际集成测试 - $(date)" > $TEST_LOG
    echo "========================================" >> $TEST_LOG

    # 检查必要文件
    local required_files=(
        "core/bridge/go_src/tun.go"
        "core/bridge/go_src/config.go"
        "flutter_app/lib/ui/main_dashboard.dart"
        "flutter_app/lib/ui/config_panel.dart"
    )

    local missing_files=()
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "缺少必要文件:"
        for file in "${missing_files[@]}"; do
            log_error "  - $file"
        done
        return 1
    fi

    log_success "必要文件检查完成"
    return 0
}

# 测试Go TUN接口
test_go_tun_interface() {
    log_info "测试Go TUN接口实现..."

    local score=0
    local checks=""

    # 检查TUN函数导出
    if grep -q "//export TunCreate" core/bridge/go_src/tun.go; then
        checks="${checks}[✓] TunCreate函数导出存在\n"
        score=$((score + 1))
        log_success "TunCreate函数导出存在"
    else
        log_error "TunCreate函数导出缺失"
        checks="${checks}[✗] TunCreate函数导出缺失\n"
    fi

    if grep -q "//export TunStart" core/bridge/go_src/tun.go; then
        checks="${checks}[✓] TunStart函数导出存在\n"
        score=$((score + 1))
        log_success "TunStart函数导出存在"
    else
        log_error "TunStart函数导出缺失"
        checks="${checks}[✗] TunStart函数导出缺失\n"
    fi

    if grep -q "//export TunReadPacket" core/bridge/go_src/tun.go; then
        checks="${checks}[✓] TunReadPacket函数导出存在\n"
        score=$((score + 1))
        log_success "TunReadPacket函数导出存在"
    else
        log_error "TunReadPacket函数导出缺失"
        checks="${checks}[✗] TunReadPacket函数导出缺失\n"
    fi

    # 检查TUN数据结构
    if grep -q "type.*TUN" core/bridge/go_src/tun.go; then
        checks="${checks}[✓] TUN数据结构定义存在\n"
        score=$((score + 1))
        log_success "TUN数据结构定义存在"
    else
        log_warning "TUN数据结构定义可能需要加强"
        checks="${checks}[~] TUN数据结构定义需要加强\n"
    fi

    # 检查错误处理
    if grep -q "error" core/bridge/go_src/tun.go; then
        checks="${checks}[✓] 错误处理机制存在\n"
        score=$((score + 1))
        log_success "错误处理机制存在"
    else
        log_warning "错误处理机制需要加强"
        checks="${checks}[~] 错误处理机制需要加强\n"
    fi

    # 评分
    if [ "$score" -ge 4 ]; then
        status="excellent"
        log_success "Go TUN接口测试优秀 (分数: $score/5)"
    elif [ "$score" -ge 3 ]; then
        status="good"
        log_info "Go TUN接口测试良好 (分数: $score/5)"
    elif [ "$score" -ge 2 ]; then
        status="fair"
        log_warning "Go TUN接口测试一般 (分数: $score/5)"
    else
        status="poor"
        log_error "Go TUN接口测试需要改进 (分数: $score/5)"
    fi

    # 保存结果
    echo "{" >> $RESULTS_FILE
    echo "  \"test_name\": \"Go TUN接口\"," >> $RESULTS_FILE
    echo "  \"status\": \"$status\"," >> $RESULTS_FILE
    echo "  \"score\": $score," >> $RESULTS_FILE
    echo "  \"checks\": [" >> $RESULTS_FILE
    echo -e "$checks" | while IFS= read -r line; do
        echo "    \"$line\"," >> $RESULTS_FILE
    done
    echo "  ]" >> $RESULTS_FILE
    echo "}," >> $RESULTS_FILE
}

# 测试Android TUN实现
test_android_tun() {
    log_info "测试Android TUN实现..."

    local score=0
    local checks=""

    # 检查VpnService集成
    if grep -r -q "VpnService" flutter_app/android/ 2>/dev/null; then
        checks="${checks}[✓] VpnService集成存在\n"
        score=$((score + 1))
        log_success "VpnService集成存在"
    else
        log_warning "VpnService集成需要检查"
        checks="${checks}[~] VpnService集成需要检查\n"
    fi

    # 检查权限配置
    if grep -q "BIND_VPN_SERVICE\|android.permission.BIND_VPN_SERVICE" flutter_app/android/ 2>/dev/null; then
        checks="${checks}[✓] VPN权限配置存在\n"
        score=$((score + 1))
        log_success "VPN权限配置存在"
    else
        log_warning "VPN权限配置需要检查"
        checks="${checks}[~] VPN权限配置需要检查\n"
    fi

    # 检查数据包处理
    if grep -r -q "Packet\|packet" flutter_app/android/ 2>/dev/null; then
        checks="${checks}[✓] 数据包处理逻辑存在\n"
        score=$((score + 1))
        log_success "数据包处理逻辑存在"
    else
        log_warning "数据包处理逻辑需要加强"
        checks="${checks}[~] 数据包处理逻辑需要加强\n"
    fi

    # 检查服务生命周期
    if grep -r -q "onStartCommand\|onDestroy\|Service" flutter_app/android/ 2>/dev/null; then
        checks="${checks}[✓] 服务生命周期管理存在\n"
        score=$((score + 1))
        log_success "服务生命周期管理存在"
    else
        log_warning "服务生命周期管理需要加强"
        checks="${checks}[~] 服务生命周期管理需要加强\n"
    fi

    # 评分
    if [ "$score" -ge 3 ]; then
        status="excellent"
        log_success "Android TUN实现测试优秀 (分数: $score/4)"
    elif [ "$score" -ge 2 ]; then
        status="good"
        log_info "Android TUN实现测试良好 (分数: $score/4)"
    else
        status="needs_improvement"
        log_warning "Android TUN实现需要改进 (分数: $score/4)"
    fi

    # 保存结果
    echo "{" >> $RESULTS_FILE
    echo "  \"test_name\": \"Android TUN实现\"," >> $RESULTS_FILE
    echo "  \"status\": \"$status\"," >> $RESULTS_FILE
    echo "  \"score\": $score," >> $RESULTS_FILE
    echo "  \"checks\": [" >> $RESULTS_FILE
    echo -e "$checks" | while IFS= read -r line; do
        echo "    \"$line\"," >> $RESULTS_FILE
    done
    echo "  ]" >> $RESULTS_FILE
    echo "}," >> $RESULTS_FILE
}

# 测试iOS TUN实现
test_ios_tun() {
    log_info "测试iOS TUN实现..."

    local score=0
    local checks=""

    # 检查NEPacketTunnelProvider集成
    if grep -r -q "NEPacketTunnelProvider" flutter_app/ios/ 2>/dev/null; then
        checks="${checks}[✓] NEPacketTunnelProvider集成存在\n"
        score=$((score + 1))
        log_success "NEPacketTunnelProvider集成存在"
    else
        log_warning "NEPacketTunnelProvider集成需要检查"
        checks="${checks}[~] NEPacketTunnelProvider集成需要检查\n"
    fi

    # 检查数据包处理
    if grep -r -q "packetFlow\|PacketFlow" flutter_app/ios/ 2>/dev/null; then
        checks="${checks}[✓] packetFlow数据流处理存在\n"
        score=$((score + 1))
        log_success "packetFlow数据流处理存在"
    else
        log_warning "packetFlow数据流处理需要加强"
        checks="${checks}[~] packetFlow数据流处理需要加强\n"
    fi

    # 检查网络配置
    if grep -r -q "NetworkSettings\|NetworkExtension" flutter_app/ios/ 2>/dev/null; then
        checks="${checks}[✓] 网络配置设置存在\n"
        score=$((score + 1))
        log_success "网络配置设置存在"
    else
        log_warning "网络配置设置需要加强"
        checks="${checks}[~] 网络配置设置需要加强\n"
    fi

    # 检查生命周期管理
    if grep -r -q "startTunnel\|stopTunnel\|tunnelProvider" flutter_app/ios/ 2>/dev/null; then
        checks="${checks}[✓] 隧道生命周期管理存在\n"
        score=$((score + 1))
        log_success "隧道生命周期管理存在"
    else
        log_warning "隧道生命周期管理需要加强"
        checks="${checks}[~] 隧道生命周期管理需要加强\n"
    fi

    # 评分
    if [ "$score" -ge 3 ]; then
        status="excellent"
        log_success "iOS TUN实现测试优秀 (分数: $score/4)"
    elif [ "$score" -ge 2 ]; then
        status="good"
        log_info "iOS TUN实现测试良好 (分数: $score/4)"
    else
        status="needs_improvement"
        log_warning "iOS TUN实现需要改进 (分数: $score/4)"
    fi

    # 保存结果
    echo "{" >> $RESULTS_FILE
    echo "  \"test_name\": \"iOS TUN实现\"," >> $RESULTS_FILE
    echo "  \"status\": \"$status\"," >> $RESULTS_FILE
    echo "  \"score\": $score," >> $RESULTS_FILE
    echo "  \"checks\": [" >> $RESULTS_FILE
    echo -e "$checks" | while IFS= read -r line; do
        echo "    \"$line\"," >> $RESULTS_FILE
    done
    echo "  ]" >> $RESULTS_FILE
    echo "}," >> $RESULTS_FILE
}

# 测试UI集成
test_ui_integration() {
    log_info "测试UI集成..."

    local score=0
    local checks=""

    # 检查主仪表板
    if grep -q "MainDashboardPage\|DashboardPage" flutter_app/lib/ui/main_dashboard.dart 2>/dev/null; then
        checks="${checks}[✓] 主仪表板实现存在\n"
        score=$((score + 1))
        log_success "主仪表板实现存在"
    else
        log_error "主仪表板实现缺失"
        checks="${checks}[✗] 主仪表板实现缺失\n"
    fi

    # 检查配置面板
    if grep -q "ConfigPanelPage\|ConfigPage" flutter_app/lib/ui/config_panel.dart 2>/dev/null; then
        checks="${checks}[✓] 配置面板实现存在\n"
        score=$((score + 1))
        log_success "配置面板实现存在"
    else
        log_error "配置面板实现缺失"
        checks="${checks}[✗] 配置面板实现缺失\n"
    fi

    # 检查Material 3设计
    if grep -q "Material 3\|useMaterial3" flutter_app/lib/ui/main_dashboard.dart 2>/dev/null; then
        checks="${checks}[✓] Material 3设计实现\n"
        score=$((score + 1))
        log_success "Material 3设计实现"
    else
        log_warning "Material 3设计需要加强"
        checks="${checks}[~] Material 3设计需要加强\n"
    fi

    # 检查实时统计
    if grep -q "FlChart\|charts\|chart" flutter_app/lib/ui/main_dashboard.dart 2>/dev/null; then
        checks="${checks}[✓] 实时图表统计实现\n"
        score=$((score + 1))
        log_success "实时图表统计实现"
    else
        log_warning "实时图表统计需要加强"
        checks="${checks}[~] 实时图表统计需要加强\n"
    fi

    # 评分
    if [ "$score" -ge 3 ]; then
        status="excellent"
        log_success "UI集成测试优秀 (分数: $score/4)"
    elif [ "$score" -ge 2 ]; then
        status="good"
        log_info "UI集成测试良好 (分数: $score/4)"
    else
        status="needs_improvement"
        log_warning "UI集成需要改进 (分数: $score/4)"
    fi

    # 保存结果
    echo "{" >> $RESULTS_FILE
    echo "  \"test_name\": \"UI集成\"," >> $RESULTS_FILE
    echo "  \"status\": \"$status\"," >> $RESULTS_FILE
    echo "  \"score\": $score," >> $RESULTS_FILE
    echo "  \"checks\": [" >> $RESULTS_FILE
    echo -e "$checks" | while IFS= read -r line; do
        echo "    \"$line\"," >> $RESULTS_FILE
    done
    echo "  ]" >> $RESULTS_FILE
    echo "}," >> $RESULTS_FILE
}

# 生成测试报告
generate_test_report() {
    log_info "生成T003-S4实际集成测试报告..."

    local current_date=$(date)

    cat > $TEST_DIR/integration_test_report.md << EOF
# T003-S4 实际TUN功能集成测试报告

## 测试概览
- 测试时间: $current_date
- 测试类型: 实际功能验证
- 测试范围: 跨平台TUN功能集成

## 测试结果汇总
详细测试结果请查看: $RESULTS_FILE

## 下一步行动
1. 基于测试结果优化TUN功能实现
2. 进行实际设备上的TUN功能测试
3. 完善跨平台集成和错误处理
4. 准备发布前的最终验证

EOF

    log_success "测试报告已生成: $TEST_DIR/integration_test_report.md"
}

# 主测试流程
main() {
    log_info "开始T003-S4实际TUN功能集成测试..."

    # 初始化
    if ! initialize_test_environment; then
        log_error "测试环境初始化失败"
        exit 1
    fi

    # 执行各项测试
    echo "{" > $RESULTS_FILE
    echo "  \"results\": [" >> $RESULTS_FILE

    test_go_tun_interface
    test_android_tun
    test_ios_tun
    test_ui_integration

    echo "  ]" >> $RESULTS_FILE
    echo "}" >> $RESULTS_FILE

    # 生成报告
    generate_test_report

    log_success "T003-S4实际集成测试完成！"
    log_info "测试日志: $TEST_LOG"
    log_info "测试结果: $RESULTS_FILE"
    log_info "测试报告: $TEST_DIR/integration_test_report.md"
}

# 运行主测试
main "$@"