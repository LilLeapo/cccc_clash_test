#!/bin/bash

# Mihomo Flutter Cross 完整构建脚本
# 支持Android、iOS、桌面端统一构建

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="Mihomo Flutter Cross"
VERSION="0.1.0-alpha"
BUILD_NUMBER="1"
PACKAGE_NAME="com.mihomo.flutter"

# 目录配置
FLUTTER_APP_DIR="flutter_app"
BUILD_DIR="build"
RELEASE_DIR="release"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查构建依赖..."

    # 检查Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter未安装，请先安装Flutter SDK"
        exit 1
    fi

    # 检查Flutter版本
    flutter_version=$(flutter --version | head -n 1)
    log_info "Flutter版本: $flutter_version"

    # 检查Dart版本
    dart_version=$(dart --version | head -n 1)
    log_info "Dart版本: $dart_version"

    log_success "依赖检查完成"
}

# 清理构建缓存
clean_build() {
    log_info "清理构建缓存..."

    cd $FLUTTER_APP_DIR
    flutter clean
    flutter pub get

    cd ..
    mkdir -p $BUILD_DIR
    mkdir -p $RELEASE_DIR

    log_success "构建缓存清理完成"
}

# 构建Android
build_android() {
    log_info "开始构建Android应用..."

    cd $FLUTTER_APP_DIR

    # 构建AAB (Android App Bundle)
    log_info "构建Android App Bundle..."
    flutter build appbundle \
        --release \
        --target-platform android-arm64,android-arm \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION

    if [ $? -eq 0 ]; then
        log_success "AAB构建成功"
        cp build/app/outputs/bundle/release/app-release.aab ../$RELEASE_DIR/
    else
        log_error "AAB构建失败"
        return 1
    fi

    # 构建APK
    log_info "构建Android APK..."
    flutter build apk \
        --release \
        --target-platform android-arm64,android-arm \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION

    if [ $? -eq 0 ]; then
        log_success "APK构建成功"
        cp build/app/outputs/flutter-apk/app-release.apk ../$RELEASE_DIR/
    else
        log_error "APK构建失败"
        return 1
    fi

    cd ..
    log_success "Android构建完成"
}

# 构建iOS
build_ios() {
    log_info "开始构建iOS应用..."

    cd $FLUTTER_APP_DIR

    # 构建iOS (需要macOS和Xcode)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "构建iOS应用..."
        flutter build ios \
            --release \
            --build-number=$BUILD_NUMBER \
            --build-name=$VERSION \
            --no-codesign

        if [ $? -eq 0 ]; then
            log_success "iOS构建成功"
            cp -r build/ios/iphoneos/ ../$RELEASE_DIR/ios-app/
        else
            log_error "iOS构建失败"
            return 1
        fi
    else
        log_warning "当前平台不支持iOS构建 (需要macOS)"
        return 1
    fi

    cd ..
    log_success "iOS构建完成"
}

# 构建Windows
build_windows() {
    log_info "开始构建Windows应用..."

    cd $FLUTTER_APP_DIR

    # 启用Windows桌面支持
    flutter config --enable-windows-desktop

    log_info "构建Windows应用..."
    flutter build windows \
        --release \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION

    if [ $? -eq 0 ]; then
        log_success "Windows构建成功"
        cp -r build/windows/x64/runner/Release/* ../$RELEASE_DIR/windows-app/
    else
        log_error "Windows构建失败"
        return 1
    fi

    cd ..
    log_success "Windows构建完成"
}

# 构建macOS
build_macos() {
    log_info "开始构建macOS应用..."

    cd $FLUTTER_APP_DIR

    # 启用macOS桌面支持
    flutter config --enable-macos-desktop

    log_info "构建macOS应用..."
    flutter build macos \
        --release \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION

    if [ $? -eq 0 ]; then
        log_success "macOS构建成功"
        cp -r build/macos/Build/Products/Release/mihomo_flutter_cross.app ../$RELEASE_DIR/macos-app/
    else
        log_error "macOS构建失败"
        return 1
    fi

    cd ..
    log_success "macOS构建完成"
}

# 构建Linux
build_linux() {
    log_info "开始构建Linux应用..."

    cd $FLUTTER_APP_DIR

    # 启用Linux桌面支持
    flutter config --enable-linux-desktop

    log_info "构建Linux应用..."
    flutter build linux \
        --release \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION

    if [ $? -eq 0 ]; then
        log_success "Linux构建成功"
        cp -r build/linux/x64/release/bundle/* ../$RELEASE_DIR/linux-app/
    else
        log_error "Linux构建失败"
        return 1
    fi

    cd ..
    log_success "Linux构建完成"
}

# 创建发布包
create_release_package() {
    log_info "创建发布包..."

    cd $RELEASE_DIR

    # 创建版本信息文件
    cat > version.txt << EOF
$PROJECT_NAME
Version: $VERSION
Build: $BUILD_NUMBER
Package: $PACKAGE_NAME
Build Date: $(date)
Platform: $(uname -s)
Architecture: $(uname -m)
EOF

    # 创建压缩包
    tar -czf "${PROJECT_NAME// /_}-${VERSION}-release.tar.gz" *.apk *.aab ios-app/ windows-app/ macos-app/ linux-app/ version.txt

    cd ..
    log_success "发布包创建完成"
}

# 生成构建报告
generate_build_report() {
    log_info "生成构建报告..."

    cat > $RELEASE_DIR/build_report.md << EOF
# $PROJECT_NAME 构建报告

## 构建信息
- **项目名称**: $PROJECT_NAME
- **版本**: $VERSION
- **构建编号**: $BUILD_NUMBER
- **包名**: $PACKAGE_NAME
- **构建时间**: $(date)
- **构建平台**: $(uname -s)
- **架构**: $(uname -m)

## 构建产物
EOF

    # 添加构建产物信息
    cd $RELEASE_DIR

    if [ -f "app-release.aab" ]; then
        echo "- **Android AAB**: app-release.aab ($(du -h app-release.aab | cut -f1))" >> build_report.md
    fi

    if [ -f "app-release.apk" ]; then
        echo "- **Android APK**: app-release.apk ($(du -h app-release.apk | cut -f1))" >> build_report.md
    fi

    if [ -d "ios-app" ]; then
        echo "- **iOS应用**: ios-app/ (包含.app和符号文件)" >> build_report.md
    fi

    if [ -d "windows-app" ]; then
        echo "- **Windows应用**: windows-app/ (包含.exe和DLL文件)" >> build_report.md
    fi

    if [ -d "macos-app" ]; then
        echo "- **macOS应用**: macos-app/mihomo_flutter_cross.app" >> build_report.md
    fi

    if [ -d "linux-app" ]; then
        echo "- **Linux应用**: linux-app/ (包含可执行文件和资源)" >> build_report.md
    fi

    echo "" >> build_report.md
    echo "## 验证清单" >> build_report.md
    echo "- [ ] Android AAB在Google Play Console中上传成功" >> build_report.md
    echo "- [ ] Android APK在测试设备上安装运行正常" >> build_report.md
    echo "- [ ] iOS应用在TestFlight中可下载安装" >> build_report.md
    echo "- [ ] Windows应用在目标系统上运行正常" >> build_report.md
    echo "- [ ] macOS应用在目标系统上运行正常" >> build_report.md
    echo "- [ ] Linux应用在目标系统上运行正常" >> build_report.md

    cd ..
    log_success "构建报告生成完成"
}

# 显示帮助信息
show_help() {
    echo "Mihomo Flutter Cross 构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --all          构建所有平台 (默认)"
    echo "  --android      仅构建Android"
    echo "  --ios          仅构建iOS"
    echo "  --windows      仅构建Windows"
    echo "  --macos        仅构建macOS"
    echo "  --linux        仅构建Linux"
    echo "  --clean        仅清理构建缓存"
    echo "  --help         显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --all                    # 构建所有平台"
    echo "  $0 --android                # 仅构建Android"
    echo "  $0 --ios --android          # 构建iOS和Android"
    echo ""
}

# 主函数
main() {
    log_info "开始 $PROJECT_NAME 构建流程..."
    log_info "版本: $VERSION | 构建编号: $BUILD_NUMBER"
    echo ""

    # 检查依赖
    check_dependencies

    # 清理构建缓存
    clean_build

    # 根据参数构建不同平台
    case "${1:---all}" in
        --all)
            log_info "构建所有平台..."
            build_android
            build_ios
            build_windows
            build_macos
            build_linux
            ;;
        --android)
            build_android
            ;;
        --ios)
            build_ios
            ;;
        --windows)
            build_windows
            ;;
        --macos)
            build_macos
            ;;
        --linux)
            build_linux
            ;;
        --clean)
            log_info "仅清理构建缓存"
            exit 0
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac

    # 创建发布包
    create_release_package

    # 生成构建报告
    generate_build_report

    echo ""
    log_success "构建流程完成！"
    log_info "构建产物位置: $RELEASE_DIR/"
    log_info "发布包: $RELEASE_DIR/${PROJECT_NAME// /_}-${VERSION}-release.tar.gz"
    log_info "构建报告: $RELEASE_DIR/build_report.md"
}

# 运行主函数
main "$@"