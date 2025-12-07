// JNI桥接层 - Android Native与Go内核通信
// 提供Java/Kotlin与Go TUN接口的桥接

#include <jni.h>
#include <android/log.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#define TAG "MihomoJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)

// 全局变量
static JavaVM* g_vm = NULL;
static jclass g_mihomo_core_class = NULL;
static jobject g_mihomo_core_instance = NULL;

// 函数声明
extern "C" {
    // Go函数声明
    int InitializeCore(const char* configPath);
    int StartMihomoProxy();
    int StopMihomoProxy();
    int GetMihomoStatus(char* buffer, int bufferSize);
    char* GetMihomoVersion();
    int TunCreate(const char* tunName);
    int TunStart();
    int TunStop();
    char* TunReadPacket();
    int TunWritePacket(const char* packetData);
    char* GetTunStats();
    int ResetTunStats();
}

// JNI_OnLoad - JNI库加载时调用
extern "C" JNIEXPORT jint JNICALL
JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("Mihomo JNI库加载中...");
    g_vm = vm;

    JNIEnv* env;
    if (vm->GetEnv((void**)&env, JNI_VERSION_1_8) != JNI_OK) {
        LOGE("获取JNIEnv失败");
        return JNI_ERR;
    }

    LOGI("Mihomo JNI库加载成功");
    return JNI_VERSION_1_8;
}

// JNI_OnUnload - JNI库卸载时调用
extern "C" JNIEXPORT void JNICALL
JNI_OnUnload(JavaVM* vm, void* reserved) {
    LOGI("Mihomo JNI库卸载中...");
    g_vm = vm;
}

// Helper函数：创建UTF8字符串
static jstring createUTF8String(JNIEnv* env, const char* str) {
    if (!str) return env->NewStringUTF("");
    return env->NewStringUTF(str);
}

// Helper函数：复制字符串
static char* copyString(const char* str) {
    if (!str) return nullptr;
    size_t len = strlen(str);
    char* result = (char*)malloc(len + 1);
    if (result) {
        strcpy(result, str);
    }
    return result;
}

// Native方法实现

// initializeMihomo
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeInitializeMihomo(
    JNIEnv* env, jobject thiz, jstring configPath) {

    const char* configPathStr = env->GetStringUTFChars(configPath, nullptr);
    if (!configPathStr) {
        LOGE("无法获取配置路径");
        return JNI_FALSE;
    }

    LOGI("初始化Mihomo: %s", configPathStr);

    int result = InitializeCore(configPathStr);
    env->ReleaseStringUTFChars(configPath, configPathStr);

    if (result == 0) {
        LOGI("Mihomo初始化成功");
        return JNI_TRUE;
    } else {
        LOGE("Mihomo初始化失败: %d", result);
        return JNI_FALSE;
    }
}

// startProxy
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeStartProxy(
    JNIEnv* env, jobject thiz) {

    LOGI("启动Mihomo代理");

    int result = StartMihomoProxy();
    if (result == 0) {
        LOGI("Mihomo代理启动成功");
        return JNI_TRUE;
    } else {
        LOGE("Mihomo代理启动失败: %d", result);
        return JNI_FALSE;
    }
}

// stopProxy
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeStopProxy(
    JNIEnv* env, jobject thiz) {

    LOGI("停止Mihomo代理");

    int result = StopMihomoProxy();
    if (result == 0) {
        LOGI("Mihomo代理停止成功");
        return JNI_TRUE;
    } else {
        LOGE("Mihomo代理停止失败: %d", result);
        return JNI_FALSE;
    }
}

// getStatus
extern "C" JNIEXPORT jstring JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeGetStatus(
    JNIEnv* env, jobject thiz) {

    LOGD("获取Mihomo状态");

    char buffer[1024];
    int result = GetMihomoStatus(buffer, sizeof(buffer));

    if (result > 0) {
        LOGI("状态获取成功: %s", buffer);
        return createUTF8String(env, buffer);
    } else {
        LOGE("状态获取失败");
        return createUTF8String(env, "{\"status\": \"error\"}");
    }
}

// getVersion
extern "C" JNIEXPORT jstring JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeGetVersion(
    JNIEnv* env, jobject thiz) {

    LOGD("获取Mihomo版本");

    char* version = GetMihomoVersion();
    if (version) {
        LOGI("版本: %s", version);
        jstring result = createUTF8String(env, version);
        free(version);
        return result;
    } else {
        LOGE("版本获取失败");
        return createUTF8String(env, "error");
    }
}

// tunCreate
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeTunCreate(
    JNIEnv* env, jobject thiz, jstring tunName) {

    const char* tunNameStr = env->GetStringUTFChars(tunName, nullptr);
    if (!tunNameStr) {
        LOGE("无法获取TUN名称");
        return JNI_FALSE;
    }

    LOGI("创建TUN接口: %s", tunNameStr);

    int result = TunCreate(tunNameStr);
    env->ReleaseStringUTFChars(tunName, tunNameStr);

    if (result == 0) {
        LOGI("TUN接口创建成功");
        return JNI_TRUE;
    } else {
        LOGE("TUN接口创建失败: %d", result);
        return JNI_FALSE;
    }
}

// tunStart
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeTunStart(
    JNIEnv* env, jobject thiz) {

    LOGI("启动TUN模式");

    int result = TunStart();
    if (result == 0) {
        LOGI("TUN模式启动成功");
        return JNI_TRUE;
    } else {
        LOGE("TUN模式启动失败: %d", result);
        return JNI_FALSE;
    }
}

// tunStop
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeTunStop(
    JNIEnv* env, jobject thiz) {

    LOGI("停止TUN模式");

    int result = TunStop();
    if (result == 0) {
        LOGI("TUN模式停止成功");
        return JNI_TRUE;
    } else {
        LOGE("TUN模式停止失败: %d", result);
        return JNI_FALSE;
    }
}

// tunReadPacket
extern "C" JNIEXPORT jstring JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeTunReadPacket(
    JNIEnv* env, jobject thiz) {

    LOGD("从TUN读取数据包");

    char* packet = TunReadPacket();
    if (packet) {
        jstring result = createUTF8String(env, packet);
        free(packet);
        return result;
    } else {
        LOGD("TUN读取数据包为空");
        return createUTF8String(env, "null");
    }
}

// tunWritePacket
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeTunWritePacket(
    JNIEnv* env, jobject thiz, jstring packetData) {

    const char* packetDataStr = env->GetStringUTFChars(packetData, nullptr);
    if (!packetDataStr) {
        LOGE("无法获取数据包内容");
        return JNI_FALSE;
    }

    LOGD("向TUN写入数据包: %d 字节", (int)strlen(packetDataStr));

    int result = TunWritePacket(packetDataStr);
    env->ReleaseStringUTFChars(packetData, packetDataStr);

    if (result == 0) {
        return JNI_TRUE;
    } else {
        LOGE("TUN写入数据包失败: %d", result);
        return JNI_FALSE;
    }
}

// getTunStats
extern "C" JNIEXPORT jstring JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeGetTunStats(
    JNIEnv* env, jobject thiz) {

    LOGD("获取TUN统计信息");

    char* stats = GetTunStats();
    if (stats) {
        jstring result = createUTF8String(env, stats);
        free(stats);
        return result;
    } else {
        LOGE("TUN统计获取失败");
        return createUTF8String(env, "{}");
    }
}

// resetTunStats
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeResetTunStats(
    JNIEnv* env, jobject thiz) {

    LOGI("重置TUN统计");

    int result = ResetTunStats();
    if (result == 0) {
        return JNI_TRUE;
    } else {
        LOGE("TUN统计重置失败: %d", result);
        return JNI_FALSE;
    }
}

// logMessage - 日志回调
extern "C" JNIEXPORT void JNICALL
Java_com_mihomoflutter_core_MihomoCore_nativeLogMessage(
    JNIEnv* env, jobject thiz, jstring level, jstring message) {

    const char* levelStr = env->GetStringUTFChars(level, nullptr);
    const char* messageStr = env->GetStringUTFChars(message, nullptr);

    if (levelStr && messageStr) {
        if (strcmp(levelStr, "error") == 0) {
            LOGE("%s", messageStr);
        } else if (strcmp(levelStr, "warn") == 0) {
            LOGE("%s", messageStr);
        } else {
            LOGI("%s", messageStr);
        }
    }

    if (levelStr) env->ReleaseStringUTFChars(level, levelStr);
    if (messageStr) env->ReleaseStringUTFChars(message, messageStr);
}