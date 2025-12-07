#!/bin/bash

echo "🔍 验证Bundle ID统一修复"
echo "================================="

# 检查Android配置
echo ""
echo "📱 Android配置检查:"
echo "--------------------"

GRADLE_FILE="flutter_app/android/app/build.gradle"
if [ -f "$GRADLE_FILE" ]; then
    # 检查applicationId
    APP_ID=$(grep 'applicationId' "$GRADLE_FILE" | grep -o '"[^"]*"' | tr -d '"')
    echo "  ✅ applicationId: $APP_ID"
    
    # 检查namespace
    NAMESPACE=$(grep 'namespace' "$GRADLE_FILE" | grep -o "'[^']*'" | tr -d "'")
    echo "  ✅ namespace: $NAMESPACE"
    
    if [ "$APP_ID" = "com.mihomo.flutter" ] && [ "$NAMESPACE" = "com.mihomo.flutter" ]; then
        echo "  ✅ Android Bundle ID统一成功"
    else
        echo "  ❌ Android Bundle ID未统一"
    fi
else
    echo "  ❌ Android build.gradle文件不存在"
fi

# 检查AndroidManifest
echo ""
MANIFEST_FILE="flutter_app/android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST_FILE" ]; then
    PACKAGE=$(grep 'package=' "$MANIFEST_FILE" | grep -o '"[^"]*"' | tr -d '"')
    echo "  ✅ AndroidManifest package: $PACKAGE"
    if [ "$PACKAGE" = "com.mihomo.flutter" ]; then
        echo "  ✅ Android Manifest包名统一成功"
    else
        echo "  ❌ Android Manifest包名未统一"
    fi
else
    echo "  ❌ AndroidManifest.xml文件不存在"
fi

# 检查iOS配置
echo ""
echo "🍎 iOS配置检查:"
echo "----------------"

IOS_BASE_CONFIG="flutter_app/ios/Base.xcconfig"
if [ -f "$IOS_BASE_CONFIG" ]; then
    BASE_ID=$(grep 'BASE_BUNDLE_IDENTIFIER' "$IOS_BASE_CONFIG" | cut -d'=' -f2)
    echo "  ✅ BASE_BUNDLE_IDENTIFIER: $BASE_ID"
    
    if [ "$BASE_ID" = "com.mihomo.flutter" ]; then
        echo "  ✅ iOS Bundle ID统一成功"
    else
        echo "  ❌ iOS Bundle ID未统一"
    fi
else
    echo "  ❌ iOS Base.xcconfig文件不存在"
fi

# 检查Go Mobile支持
echo ""
echo "⚙️  Go Mobile支持检查:"
echo "----------------------"

GOMOBILE_SCRIPT="flutter_app/android/build_gomobile.gradle"
if [ -f "$GOMOBILE_SCRIPT" ]; then
    echo "  ✅ Go Mobile构建脚本存在"
else
    echo "  ❌ Go Mobile构建脚本缺失"
fi

# 检查依赖
GRADLE_FILE="flutter_app/android/app/build.gradle"
if [ -f "$GRADLE_FILE" ]; then
    if grep -q "org.golang.mobile:mobile" "$GRADLE_FILE"; then
        echo "  ✅ Go Mobile依赖已添加"
    else
        echo "  ❌ Go Mobile依赖缺失"
    fi
fi

# 总结
echo ""
echo "📊 修复总结:"
echo "============"

TOTAL_CHECKS=0
PASSED_CHECKS=0

# Android检查
if [ -f "$GRADLE_FILE" ]; then
    ((TOTAL_CHECKS++))
    if [ "$APP_ID" = "com.mihomo.flutter" ] && [ "$NAMESPACE" = "com.mihomo.flutter" ]; then
        ((PASSED_CHECKS++))
    fi
fi

# iOS检查
if [ -f "$IOS_BASE_CONFIG" ]; then
    ((TOTAL_CHECKS++))
    if [ "$BASE_ID" = "com.mihomo.flutter" ]; then
        ((PASSED_CHECKS++))
    fi
fi

# Android Manifest检查
if [ -f "$MANIFEST_FILE" ]; then
    ((TOTAL_CHECKS++))
    if [ "$PACKAGE" = "com.mihomo.flutter" ]; then
        ((PASSED_CHECKS++))
    fi
fi

# Go Mobile检查
if [ -f "$GOMOBILE_SCRIPT" ] && [ -f "$GRADLE_FILE" ] && grep -q "org.golang.mobile:mobile" "$GRADLE_FILE"; then
    ((TOTAL_CHECKS++))
    ((PASSED_CHECKS++))
fi

echo "  通过: $PASSED_CHECKS/$TOTAL_CHECKS"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo "  🎉 Bundle ID统一修复成功！"
    echo ""
    echo "🚀 下一步可以进行的操作:"
    echo "  1. 运行 flutter clean && flutter pub get"
    echo "  2. 测试Android编译: cd flutter_app && ./gradlew assembleDebug"
    echo "  3. 验证Go Mobile绑定生成"
else
    echo "  ⚠️  部分修复未完成，请检查上述错误"
fi

echo ""
