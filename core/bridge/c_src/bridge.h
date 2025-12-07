// Bridge层 - C接口头文件
// 用于Dart FFI绑定和桌面端编译

#ifndef MIHOOMO_BRIDGE_H
#define MIHOOMO_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

// C字符串类型
typedef char* GoString;

// 返回值常量
#define MIHOOMO_SUCCESS 0
#define MIHOOMO_ERROR   1
#define MIHOOMO_RUNNING 2

// =============================================================================
// 核心生命周期管理
// =============================================================================

/**
 * 初始化Mihomo核心
 * @param configPath 配置文件路径
 * @return 0=成功, 其他=错误码
 */
int32_t InitializeCore(GoString configPath);

/**
 * 启动Mihomo代理服务
 * @return 0=成功, 1=已运行, 其他=错误码
 */
int32_t StartMihomoProxy();

/**
 * 停止Mihomo代理服务
 * @return 0=成功, 1=未运行, 其他=错误码
 */
int32_t StopMihomoProxy();

/**
 * 重载配置
 * @param configPath 新的配置文件路径，空字符串使用原配置
 * @return 0=成功, 其他=错误码
 */
int32_t ReloadConfig(GoString configPath);

/**
 * 获取当前状态信息
 * @return JSON格式的状态字符串，需要调用者释放内存
 */
GoString GetMihomoStatus();

/**
 * 获取版本信息
 * @return 版本字符串，需要调用者释放内存
 */
GoString GetMihomoVersion();

// =============================================================================
// 日志和调试
// =============================================================================

/**
 * 日志回调函数
 * @param logLevel 日志级别
 * @param message 日志消息
 */
void LogCallback(GoString logLevel, GoString message);

/**
 * 设置日志级别
 * @param level 日志级别字符串
 * @return 0=成功, 其他=错误码
 */
int32_t SetLogLevel(GoString level);

/**
 * Hello World测试函数
 * @return 测试消息字符串，需要调用者释放内存
 */
GoString HelloWorld();

// =============================================================================
// TUN模式流量处理
// =============================================================================

/**
 * 创建TUN接口
 * @param tunName TUN接口名称
 * @return 0=成功, 其他=错误码
 */
int32_t TunCreate(GoString tunName);

/**
 * 启动TUN流量处理
 * @return 0=成功, 1=代理未运行, 其他=错误码
 */
int32_t TunStart();

/**
 * 停止TUN流量处理
 * @return 0=成功, 其他=错误码
 */
int32_t TunStop();

/**
 * 从TUN读取数据包
 * @return JSON格式的数据包信息，需要调用者释放内存
 */
GoString TunReadPacket();

/**
 * 向TUN写入数据包
 * @param packetData JSON格式的数据包信息
 * @return 0=成功, 其他=错误码
 */
int32_t TunWritePacket(GoString packetData);

// =============================================================================
// 流量统计
// =============================================================================

/**
 * 获取流量统计信息
 * @return JSON格式的统计信息，需要调用者释放内存
 */
GoString GetTrafficStats();

/**
 * 重置流量统计
 * @return 0=成功, 其他=错误码
 */
int32_t ResetTrafficStats();

// =============================================================================
// 内存管理辅助函数
// =============================================================================

/**
 * 释放由Go函数返回的字符串内存
 * @param str 要释放的字符串指针
 */
void FreeString(GoString str);

/**
 * 获取Go字符串长度
 * @param str Go字符串
 * @return 字符串长度
 */
int32_t GetStringLength(GoString str);

// =============================================================================
// 配置管理
// =============================================================================

/**
 * 加载YAML配置文件
 * @param filePath 配置文件路径
 * @return JSON格式的结果，需要调用者释放内存
 */
GoString ConfigLoad(GoString filePath);

/**
 * 保存配置到YAML文件
 * @param configJSON JSON格式的配置数据
 * @param filePath 保存路径，为空时使用当前配置路径
 * @return JSON格式的结果，需要调用者释放内存
 */
GoString ConfigSave(GoString configJSON, GoString filePath);

/**
 * 获取当前配置
 * @return JSON格式的配置信息，需要调用者释放内存
 */
GoString ConfigGetCurrent();

/**
 * 验证配置格式
 * @param configJSON JSON格式的配置数据
 * @return JSON格式的验证结果，需要调用者释放内存
 */
GoString ConfigValidate(GoString configJSON);

/**
 * 将YAML配置转换为JSON
 * @param configYAML YAML格式的配置数据
 * @return JSON格式的结果，需要调用者释放内存
 */
GoString ConfigToJSON(GoString configYAML);

/**
 * 从JSON配置转换为YAML
 * @param configJSON JSON格式的配置数据
 * @return YAML格式的结果，需要调用者释放内存
 */
GoString ConfigFromJSON(GoString configJSON);

/**
 * 列出可用配置文件
 * @param dirPath 目录路径，为空时使用当前目录
 * @return JSON格式的配置文件列表，需要调用者释放内存
 */
GoString ConfigListProfiles(GoString dirPath);

/**
 * 配置热重载
 * @return JSON格式的重载结果，需要调用者释放内存
 */
GoString ConfigHotReload();

// =============================================================================
// 错误处理
// =============================================================================

/**
 * 获取最后的错误信息
 * @return 错误信息字符串，需要调用者释放内存
 */
GoString GetLastError();

/**
 * 清除错误信息
 */
void ClearError();

// =============================================================================
// 平台特定的函数
// =============================================================================

#ifdef __ANDROID__
    // Android特定的实现
    #include <jni.h>

    JNIEXPORT void JNICALL
    Java_com_mihomo_flutter_1cross_MihomoCore_nativeLog(JNIEnv *env, jobject thiz, jstring level, jstring message);
#endif

#ifdef __APPLE__
    // macOS/iOS特定的实现
    #include <Foundation/Foundation.h>

    void SetupAppleLogging();
#endif

#ifdef _WIN32
    // Windows特定的实现
    #include <windows.h>

    HANDLE SetupWindowsLogging();
#endif

#ifdef __cplusplus
}
#endif

#endif // MIHOOMO_BRIDGE_H