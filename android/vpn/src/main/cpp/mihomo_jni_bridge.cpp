#include <jni.h>
#include <android/log.h>
#include <string>
#include <cstring>

#define LOG_TAG "MihomoJni"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Go函数声明
extern "C" {
    // TUN相关函数
    int TunCreate();
    int TunStart(const char* config);
    int TunStop();
    int TunReadPacket(int fd, void* buffer, int length);
    int TunWritePacket(int fd, const void* buffer, int length);

    // 配置相关函数
    const char* LoadConfigFile(const char* path);
    int SaveConfigFile(const char* path, const char* data);
    const char* GetConfigValue(const char* key);
    int SetConfigValue(const char* key, const char* value);
}

// 辅助函数：将jstring转换为C字符串
static char* jni_get_string(JNIEnv *env, jstring jstr) {
    if (!jstr) return nullptr;
    const char* cstr = env->GetStringUTFChars(jstr, nullptr);
    if (!cstr) return nullptr;

    char* result = strdup(cstr);
    env->ReleaseStringUTFChars(jstr, cstr);
    return result;
}

// 辅助函数：创建jstring
static jstring jni_new_string(JNIEnv *env, const char* cstr) {
    if (!cstr) return nullptr;
    return env->NewStringUTF(cstr);
}

// Java包名映射
static const char* kJavaClassPath = "com/mihomo/flutter_cross/core/MihomoCore";

/**
 * JNI入口点：库加载时调用
 */
extern "C" jint JNICALL
JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("Mihomo JNI Library loaded");
    return JNI_VERSION_1_6;
}

/**
 * TUN接口相关函数
 */

// 创建TUN接口
extern "C" JNIEXPORT jint JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_tunCreate(
    JNIEnv* env, jobject thiz, jstring j_interface_name) {

    char* interface_name = jni_get_string(env, j_interface_name);
    if (!interface_name) {
        LOGE("Failed to get interface name");
        return -1;
    }

    LOGI("Creating TUN interface: %s", interface_name);
    int result = TunCreate();

    free(interface_name);
    return result;
}

// 启动TUN服务
extern "C" JNIEXPORT jint JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_tunStart(
    JNIEnv* env, jobject thiz, jstring j_config) {

    char* config = jni_get_string(env, j_config);
    if (!config) {
        LOGE("Failed to get config");
        return -1;
    }

    LOGI("Starting TUN service");
    int result = TunStart(config);

    free(config);
    return result;
}

// 停止TUN服务
extern "C" JNIEXPORT jint JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_tunStop(
    JNIEnv* env, jobject thiz) {

    LOGI("Stopping TUN service");
    return TunStop();
}

// 读取数据包
extern "C" JNIEXPORT jint JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_tunReadPacket(
    JNIEnv* env, jobject thiz, jint j_fd, jobject j_buffer, jint j_length) {

    if (!j_buffer) {
        LOGE("Buffer is null");
        return -1;
    }

    void* buffer = env->GetDirectBufferAddress(j_buffer);
    if (!buffer) {
        LOGE("Failed to get buffer address");
        return -1;
    }

    return TunReadPacket(j_fd, buffer, j_length);
}

// 写入数据包
extern "C" JNIEXPORT jint JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_tunWritePacket(
    JNIEnv* env, jobject thiz, jint j_fd, jobject j_buffer, jint j_length) {

    if (!j_buffer) {
        LOGE("Buffer is null");
        return -1;
    }

    const void* buffer = env->GetDirectBufferAddress(j_buffer);
    if (!buffer) {
        LOGE("Failed to get buffer address");
        return -1;
    }

    return TunWritePacket(j_fd, buffer, j_length);
}

/**
 * 配置管理相关函数
 */

// 加载配置文件
extern "C" JNIEXPORT jstring JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_loadConfigFile(
    JNIEnv* env, jobject thiz, jstring j_path) {

    char* path = jni_get_string(env, j_path);
    if (!path) {
        LOGE("Failed to get config path");
        return nullptr;
    }

    LOGI("Loading config file: %s", path);
    const char* result = LoadConfigFile(path);

    free(path);

    if (!result) {
        LOGE("Failed to load config file");
        return nullptr;
    }

    jstring j_result = jni_new_string(env, result);
    // 注意：这里假设Go函数返回的内存会被释放
    return j_result;
}

// 保存配置文件
extern "C" JNIEXPORT jint JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_saveConfigFile(
    JNIEnv* env, jobject thiz, jstring j_path, jstring j_data) {

    char* path = jni_get_string(env, j_path);
    char* data = jni_get_string(env, j_data);

    if (!path || !data) {
        LOGE("Failed to get path or data");
        if (path) free(path);
        if (data) free(data);
        return -1;
    }

    LOGI("Saving config file: %s", path);
    int result = SaveConfigFile(path, data);

    free(path);
    free(data);
    return result;
}

// 获取配置值
extern "C" JNIEXPORT jstring JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_getConfigValue(
    JNIEnv* env, jobject thiz, jstring j_key) {

    char* key = jni_get_string(env, j_key);
    if (!key) {
        LOGE("Failed to get config key");
        return nullptr;
    }

    const char* result = GetConfigValue(key);
    free(key);

    if (!result) {
        LOGE("Failed to get config value");
        return nullptr;
    }

    return jni_new_string(env, result);
}

// 设置配置值
extern "C" JNIEXPORT jint JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_setConfigValue(
    JNIEnv* env, jobject thiz, jstring j_key, jstring j_value) {

    char* key = jni_get_string(env, j_key);
    char* value = jni_get_string(env, j_value);

    if (!key || !value) {
        LOGE("Failed to get key or value");
        if (key) free(key);
        if (value) free(value);
        return -1;
    }

    int result = SetConfigValue(key, value);

    free(key);
    free(value);
    return result;
}

/**
 * 版本信息函数
 */
extern "C" JNIEXPORT jstring JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_getVersion(
    JNIEnv* env, jobject thiz) {
    return jni_new_string(env, "0.1.0-alpha");
}

/**
 * 初始化函数
 */
extern "C" JNIEXPORT jint JNICALL
Java_com_mihomo_flutter_1cross_core_MihomoCore_initialize(
    JNIEnv* env, jobject thiz) {
    LOGI("Initializing Mihomo Core");
    // 在这里可以进行Go核心的初始化
    return 0;
}