package main

import (
	"C"
	"fmt"
	"sync"
	"time"
)

// 全局状态管理
var (
	mu        sync.RWMutex
	isRunning bool
	configMap = make(map[string]string)
)

//export InitializeCore
func InitializeCore(configPath string) int {
	if configPath == "" {
		configPath = "default"
	}

	mu.Lock()
	defer mu.Unlock()
	configMap["path"] = configPath

	fmt.Printf("🎉 初始化核心成功! 配置: %s\n", configPath)
	return 0 // 成功
}

//export StartMihomoProxy
func StartMihomoProxy() int {
	mu.Lock()
	defer mu.Unlock()

	if isRunning {
		fmt.Println("⚠️  代理已经在运行中")
		return 1 // 已运行
	}

	isRunning = true
	fmt.Println("🚀 启动 Mihomo 代理...")

	// 模拟代理启动过程
	go func() {
		for i := 0; i < 5; i++ {
			time.Sleep(1 * time.Second)
			fmt.Printf("📊 代理运行中... (%d/5)\n", i+1)
		}
		fmt.Println("✅ Mihomo 代理启动完成")
	}()

	return 0 // 成功
}

//export StopMihomoProxy
func StopMihomoProxy() int {
	mu.Lock()
	defer mu.Unlock()

	if !isRunning {
		fmt.Println("⚠️  代理未在运行")
		return 1 // 未运行
	}

	isRunning = false
	fmt.Println("🛑 停止 Mihomo 代理...")
	return 0 // 成功
}

//export ReloadConfig
func ReloadConfig(configPath string) int {
	mu.Lock()
	defer mu.Unlock()

	if configPath != "" {
		configMap["path"] = configPath
		fmt.Printf("🔄 配置重载: %s\n", configPath)
	} else {
		fmt.Println("🔄 配置重载（使用原配置）")
	}

	if isRunning {
		fmt.Println("✅ 动态重载成功")
	} else {
		fmt.Println("⚠️  代理未运行，重载将在下次启动时生效")
	}

	return 0 // 成功
}

//export GetMihomoStatus
func GetMihomoStatus() *C.char {
	mu.RLock()
	defer mu.RUnlock()

	var status string
	if isRunning {
		status = "running"
	} else {
		status = "stopped"
	}

	configPath, exists := configMap["path"]
	if !exists {
		configPath = "default"
	}

	result := fmt.Sprintf(`{"status": "%s", "config": "%s", "version": "v0.1.0-alpha"}`, status, configPath)
	return C.CString(result)
}

//export GetMihomoVersion
func GetMihomoVersion() *C.char {
	return C.CString("v0.1.0-alpha")
}

//export LogCallback
func LogCallback(logLevel, message string) {
	// 记录日志到标准输出
	level := ""
	switch logLevel {
	case "info":
		level = "ℹ️"
	case "warn":
		level = "⚠️"
	case "error":
		level = "❌"
	case "debug":
		level = "🔍"
	default:
		level = "📝"
	}

	fmt.Printf("%s [%s] %s\n", level, logLevel, message)
}

//export SetLogLevel
func SetLogLevel(level string) int {
	mu.Lock()
	defer mu.Unlock()
	configMap["loglevel"] = level
	fmt.Printf("📝 日志级别设置为: %s\n", level)
	return 0
}

//export HelloWorld
func HelloWorld() *C.char {
	return C.CString("Hello from Mihomo-Flutter-Cross!")
}

// main 函数用于测试
func main() {
	fmt.Println("🏗️  Mihomo Flutter Cross Core 构建测试")

	// 测试初始化
	InitializeCore("test.yaml")

	// 测试启动
	StartMihomoProxy()

	// 等待一段时间
	time.Sleep(2 * time.Second)

	// 测试状态查询
	status := GetMihomoStatus()
	fmt.Printf("📊 状态: %s\n", C.GoString(status))

	// 测试停止
	StopMihomoProxy()

	fmt.Printf("👋 %s\n", HelloWorld())
	fmt.Printf("📊 版本: %s\n", GetMihomoVersion())

	// 测试日志
	LogCallback("info", "系统启动完成")
	LogCallback("warn", "这是一个测试警告")
	LogCallback("error", "这是一个测试错误")
}