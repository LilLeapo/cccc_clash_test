// Bridge层 - C实现文件
// 用于Dart FFI绑定和桌面端编译

#include "bridge.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

// 错误处理
static char last_error[512] = {0};

// =============================================================================
// 内存管理辅助函数
// =============================================================================

/**
 * 释放由Go函数返回的字符串内存
 */
void FreeString(GoString str) {
    if (str != NULL) {
        free(str);
    }
}

/**
 * 获取Go字符串长度
 */
int32_t GetStringLength(GoString str) {
    if (str == NULL) {
        return 0;
    }
    return (int32_t)strlen(str);
}

// =============================================================================
// 错误处理
// =============================================================================

/**
 * 获取最后的错误信息
 */
GoString GetLastError() {
    if (strlen(last_error) == 0) {
        return NULL;
    }
    char* error_copy = (char*)malloc(strlen(last_error) + 1);
    if (error_copy != NULL) {
        strcpy(error_copy, last_error);
    }
    return error_copy;
}

/**
 * 清除错误信息
 */
void ClearError() {
    memset(last_error, 0, sizeof(last_error));
}

// =============================================================================
// 流量统计函数
// =============================================================================

/**
 * 获取流量统计信息
 */
GoString GetTrafficStats() {
    // 模拟流量统计数据
    const char* stats = "{\"upload_bytes\": 1024000, \"download_bytes\": 2048000, \"connections\": 5}";
    
    char* stats_copy = (char*)malloc(strlen(stats) + 1);
    if (stats_copy != NULL) {
        strcpy(stats_copy, stats);
    }
    return stats_copy;
}

/**
 * 重置流量统计
 */
int32_t ResetTrafficStats() {
    printf("📊 重置流量统计\n");
    return 0;
}

// =============================================================================
// 平台特定的日志设置
// =============================================================================

#ifdef __ANDROID__
    // Android特定的实现
    #include <android/log.h>
    
    JNIEXPORT void JNICALL
    Java_com_mihomo_flutter_1cross_MihomoCore_nativeLog(JNIEnv *env, jobject thiz, jstring level, jstring message) {
        const char* level_str = (*env)->GetStringUTFChars(env, level, 0);
        const char* message_str = (*env)->GetStringUTFChars(env, message, 0);
        
        if (strcmp(level_str, "error") == 0) {
            __android_log_print(ANDROID_LOG_ERROR, "MihomoFlutter", "%s", message_str);
        } else if (strcmp(level_str, "warn") == 0) {
            __android_log_print(ANDROID_LOG_WARN, "MihomoFlutter", "%s", message_str);
        } else {
            __android_log_print(ANDROID_LOG_INFO, "MihomoFlutter", "%s", message_str);
        }
        
        (*env)->ReleaseStringUTFChars(env, level, level_str);
        (*env)->ReleaseStringUTFChars(env, message, message_str);
    }
#endif

#ifdef __APPLE__
    #include <Foundation/Foundation.h>
    void SetupAppleLogging() {
        NSLog(@"🍎 Mihomo Flutter Cross - Apple Logging Setup");
    }
#endif

#ifdef _WIN32
    #include <windows.h>
    HANDLE SetupWindowsLogging() {
        HANDLE hEventLog = RegisterEventSourceA(NULL, "MihomoFlutterCross");
        if (hEventLog != NULL) {
            printf("🪟 Windows事件日志已设置\n");
        }
        return hEventLog;
    }
#endif

// =============================================================================
// 初始化和清理
// =============================================================================

__attribute__((constructor))
static void init_bridge() {
    printf("🚀 Mihomo Flutter Cross Bridge 初始化\n");
    ClearError();
    
#ifdef __ANDROID__
    printf("📱 Android平台检测\n");
#endif

#ifdef __APPLE__
    printf("🍎 Apple平台检测\n");
    SetupAppleLogging();
#endif

#ifdef _WIN32__
    printf("🪟 Windows平台检测\n");
    SetupWindowsLogging();
#endif

#ifdef __linux__
    printf("🐧 Linux平台检测\n");
#endif
}

__attribute__((destructor))
static void cleanup_bridge() {
    printf("👋 Mihomo Flutter Cross Bridge 清理\n");
    ClearError();
}
