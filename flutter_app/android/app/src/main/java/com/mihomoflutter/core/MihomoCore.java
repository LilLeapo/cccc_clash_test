// MihomoCore Java类 - 与Go内核的JNI桥接
package com.mihomoflutter.core

import android.util.Log

class MihomoCore {
    companion object {
        private const val TAG = "MihomoCore"

        // 加载native库
        init {
            try {
                System.loadLibrary("mihomo_core")
                Log.i(TAG, "Mihomo Core库加载成功")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Mihomo Core库加载失败", e)
            }
        }
    }

    // Native方法声明
    external fun nativeInitializeMihomo(configPath: String): Boolean
    external fun nativeStartProxy(): Boolean
    external fun nativeStopProxy(): Boolean
    external fun nativeGetStatus(): String
    external fun nativeGetVersion(): String

    // TUN相关native方法
    external fun nativeTunCreate(tunName: String): Boolean
    external fun nativeTunStart(): Boolean
    external fun nativeTunStop(): Boolean
    external fun nativeTunReadPacket(): String?
    external fun nativeTunWritePacket(packetData: String): Boolean
    external fun nativeGetTunStats(): String
    external fun nativeResetTunStats(): Boolean

    // 日志回调
    external fun nativeLogMessage(level: String, message: String)

    // Java端包装方法
    fun initialize(configPath: String = "default"): Boolean {
        Log.d(TAG, "初始化Mihomo核心: $configPath")
        return try {
            val result = nativeInitializeMihomo(configPath)
            if (result) {
                Log.i(TAG, "Mihomo核心初始化成功")
                nativeLogMessage("info", "Mihomo核心初始化成功")
            } else {
                Log.e(TAG, "Mihomo核心初始化失败")
                nativeLogMessage("error", "Mihomo核心初始化失败")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "初始化异常", e)
            nativeLogMessage("error", "初始化异常: ${e.message}")
            false
        }
    }

    fun startProxy(): Boolean {
        Log.d(TAG, "启动Mihomo代理")
        return try {
            val result = nativeStartProxy()
            if (result) {
                Log.i(TAG, "Mihomo代理启动成功")
                nativeLogMessage("info", "代理启动成功")
            } else {
                Log.e(TAG, "Mihomo代理启动失败")
                nativeLogMessage("error", "代理启动失败")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "启动异常", e)
            nativeLogMessage("error", "启动异常: ${e.message}")
            false
        }
    }

    fun stopProxy(): Boolean {
        Log.d(TAG, "停止Mihomo代理")
        return try {
            val result = nativeStopProxy()
            if (result) {
                Log.i(TAG, "Mihomo代理停止成功")
                nativeLogMessage("info", "代理停止成功")
            } else {
                Log.e(TAG, "Mihomo代理停止失败")
                nativeLogMessage("error", "代理停止失败")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "停止异常", e)
            nativeLogMessage("error", "停止异常: ${e.message}")
            false
        }
    }

    fun getStatus(): Map<String, Any> {
        Log.d(TAG, "获取Mihomo状态")
        return try {
            val statusJson = nativeGetStatus()
            Log.d(TAG, "状态响应: $statusJson")
            parseStatusJson(statusJson)
        } catch (e: Exception) {
            Log.e(TAG, "获取状态异常", e)
            mapOf("status" to "error", "error" to e.message)
        }
    }

    fun getVersion(): String {
        Log.d(TAG, "获取Mihomo版本")
        return try {
            nativeGetVersion()
        } catch (e: Exception) {
            Log.e(TAG, "获取版本异常", e)
            "error"
        }
    }

    // TUN模式相关方法
    fun tunCreate(tunName: String = "mihomo-tun"): Boolean {
        Log.d(TAG, "创建TUN接口: $tunName")
        return try {
            val result = nativeTunCreate(tunName)
            if (result) {
                Log.i(TAG, "TUN接口创建成功")
                nativeLogMessage("info", "TUN接口创建成功: $tunName")
            } else {
                Log.e(TAG, "TUN接口创建失败")
                nativeLogMessage("error", "TUN接口创建失败")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "TUN创建异常", e)
            nativeLogMessage("error", "TUN创建异常: ${e.message}")
            false
        }
    }

    fun tunStart(): Boolean {
        Log.d(TAG, "启动TUN模式")
        return try {
            val result = nativeTunStart()
            if (result) {
                Log.i(TAG, "TUN模式启动成功")
                nativeLogMessage("info", "TUN模式启动成功")
            } else {
                Log.e(TAG, "TUN模式启动失败")
                nativeLogMessage("error", "TUN模式启动失败")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "TUN启动异常", e)
            nativeLogMessage("error", "TUN启动异常: ${e.message}")
            false
        }
    }

    fun tunStop(): Boolean {
        Log.d(TAG, "停止TUN模式")
        return try {
            val result = nativeTunStop()
            if (result) {
                Log.i(TAG, "TUN模式停止成功")
                nativeLogMessage("info", "TUN模式停止成功")
            } else {
                Log.e(TAG, "TUN模式停止失败")
                nativeLogMessage("error", "TUN模式停止失败")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "TUN停止异常", e)
            nativeLogMessage("error", "TUN停止异常: ${e.message}")
            false
        }
    }

    fun tunReadPacket(): String? {
        Log.d(TAG, "从TUN读取数据包")
        return try {
            val packet = nativeTunReadPacket()
            if (packet != null && packet != "null") {
                Log.d(TAG, "TUN读取数据包: ${packet.length} 字符")
                packet
            } else {
                Log.d(TAG, "TUN读取数据包为空")
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "TUN读取异常", e)
            nativeLogMessage("error", "TUN读取异常: ${e.message}")
            null
        }
    }

    fun tunWritePacket(packetData: String): Boolean {
        Log.d(TAG, "向TUN写入数据包: ${packetData.length} 字符")
        return try {
            val result = nativeTunWritePacket(packetData)
            if (result) {
                Log.d(TAG, "TUN写入数据包成功")
            } else {
                Log.e(TAG, "TUN写入数据包失败")
                nativeLogMessage("error", "TUN写入数据包失败")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "TUN写入异常", e)
            nativeLogMessage("error", "TUN写入异常: ${e.message}")
            false
        }
    }

    fun getTunStats(): Map<String, Any> {
        Log.d(TAG, "获取TUN统计")
        return try {
            val statsJson = nativeGetTunStats()
            Log.d(TAG, "TUN统计响应: $statsJson")
            parseTunStatsJson(statsJson)
        } catch (e: Exception) {
            Log.e(TAG, "获取TUN统计异常", e)
            mapOf("error" to e.message)
        }
    }

    fun resetTunStats(): Boolean {
        Log.d(TAG, "重置TUN统计")
        return try {
            val result = nativeResetTunStats()
            if (result) {
                Log.i(TAG, "TUN统计重置成功")
                nativeLogMessage("info", "TUN统计重置成功")
            } else {
                Log.e(TAG, "TUN统计重置失败")
                nativeLogMessage("error", "TUN统计重置失败")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "TUN统计重置异常", e)
            nativeLogMessage("error", "TUN统计重置异常: ${e.message}")
            false
        }
    }

    // 辅助方法
    private fun parseStatusJson(json: String): Map<String, Any> {
        return try {
            val result = mutableMapOf<String, Any>()

            // 简单的JSON解析（实际应用中应使用JSON库）
            if (json.contains("\"status\"")) {
                val statusMatch = Regex("\"status\"\\s*:\\s*\"([^\"]+)\"").find(json)
                result["status"] = statusMatch?.groupValues?.get(1) ?: "unknown"
            }

            if (json.contains("\"config\"")) {
                val configMatch = Regex("\"config\"\\s*:\\s*\"([^\"]+)\"").find(json)
                result["config"] = configMatch?.groupValues?.get(1) ?: "default"
            }

            if (json.contains("\"version\"")) {
                val versionMatch = Regex("\"version\"\\s*:\\s*\"([^\"]+)\"").find(json)
                result["version"] = versionMatch?.groupValues?.get(1) ?: "unknown"
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "解析状态JSON失败", e)
            mapOf("status" to "parse_error", "error" to e.message)
        }
    }

    private fun parseTunStatsJson(json: String): Map<String, Any> {
        return try {
            val result = mutableMapOf<String, Any>()

            // 简单的JSON解析
            if (json.contains("\"interface\"")) {
                val interfaceMatch = Regex("\"interface\"\\s*:\\s*\"([^\"]+)\"").find(json)
                result["interface"] = interfaceMatch?.groupValues?.get(1) ?: "unknown"
            }

            if (json.contains("\"active\"")) {
                val activeMatch = Regex("\"active\"\\s*:\\s*(\\w+)").find(json)
                result["active"] = activeMatch?.groupValues?.get(1)?.toBoolean() ?: false
            }

            if (json.contains("\"packetsIn\"")) {
                val packetsInMatch = Regex("\"packetsIn\"\\s*:\\s*(\\d+)").find(json)
                result["packetsIn"] = packetsInMatch?.groupValues?.get(1)?.toLongOrNull() ?: 0L
            }

            if (json.contains("\"packetsOut\"")) {
                val packetsOutMatch = Regex("\"packetsOut\"\\s*:\\s*(\\d+)").find(json)
                result["packetsOut"] = packetsOutMatch?.groupValues?.get(1)?.toLongOrNull() ?: 0L
            }

            if (json.contains("\"bytesIn\"")) {
                val bytesInMatch = Regex("\"bytesIn\"\\s*:\\s*(\\d+)").find(json)
                result["bytesIn"] = bytesInMatch?.groupValues?.get(1)?.toLongOrNull() ?: 0L
            }

            if (json.contains("\"bytesOut\"")) {
                val bytesOutMatch = Regex("\"bytesOut\"\\s*:\\s*(\\d+)").find(json)
                result["bytesOut"] = bytesOutMatch?.groupValues?.get(1)?.toLongOrNull() ?: 0L
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "解析TUN统计JSON失败", e)
            mapOf("error" to e.message)
        }
    }
}