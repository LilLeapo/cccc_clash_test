package main

import (
	"fmt"
	"sync"
	"gopkg.in/yaml.v3"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
)

// Config 全局配置结构
type Config struct {
mu sync.RWMutex
Path string `json:"path"`
Data map[string]interface{} `json:"data"`
}

// ConfigInstance 配置单例
var configInstance *Config
var configInitOnce sync.Once

// GetConfig 获取配置单例
func GetConfig() *Config {
	configInitOnce.Do(func() {
		configInstance = &Config{
			Data: make(map[string]interface{}),
		}
	})
	return configInstance
}

// LoadConfigFile 加载YAML配置文件
//export LoadConfigFile
func LoadConfigFile(configPath string) int {
	config := GetConfig()
	config.mu.Lock()
	defer config.mu.Unlock()

	if configPath == "" {
		configPath = "configs/default.yaml"
	}

	// 确保目录存在
	if err := os.MkdirAll(filepath.Dir(configPath), 0755); err != nil {
		fmt.Printf("❌ 创建配置目录失败: %v\n", err)
		return 1
	}

	// 读取文件
	data, err := os.ReadFile(configPath)
	if err != nil {
		// 如果文件不存在，创建默认配置
		fmt.Printf("⚠️  配置文件不存在，创建默认配置: %s\n", configPath)
		return createDefaultConfig(configPath)
	}

	// 解析YAML
	var configData map[string]interface{}
	if err := yaml.Unmarshal(data, &configData); err != nil {
		fmt.Printf("❌ YAML解析失败: %v\n", err)
		return 1
	}

	config.Path = configPath
	config.Data = configData

	fmt.Printf("✅ 配置文件加载成功: %s\n", configPath)
	fmt.Printf("📋 配置项数量: %d\n", len(configData))
	return 0
}

// SaveConfigFile 保存YAML配置文件
//export SaveConfigFile
func SaveConfigFile(configPath string, configData string) int {
	config := GetConfig()
	config.mu.Lock()
	defer config.mu.Unlock()

	if configPath == "" {
		configPath = config.Path
		if configPath == "" {
			configPath = "configs/default.yaml"
		}
	}

	var data map[string]interface{}
	if err := json.Unmarshal([]byte(configData), &data); err != nil {
		fmt.Printf("❌ JSON解析失败: %v\n", err)
		return 1
	}

	// 序列化YAML
	yamlData, err := yaml.Marshal(data)
	if err != nil {
		fmt.Printf("❌ YAML序列化失败: %v\n", err)
		return 1
	}

	// 确保目录存在
	if err := os.MkdirAll(filepath.Dir(configPath), 0755); err != nil {
		fmt.Printf("❌ 创建配置目录失败: %v\n", err)
		return 1
	}

	// 写入文件
	if err := os.WriteFile(configPath, yamlData, 0644); err != nil {
		fmt.Printf("❌ 保存配置文件失败: %v\n", err)
		return 1
	}

	config.Path = configPath
	config.Data = data

	fmt.Printf("✅ 配置文件保存成功: %s\n", configPath)
	return 0
}

// GetConfigValue 获取配置值
//export GetConfigValue
func GetConfigValue(key string) string {
	config := GetConfig()
	config.mu.RLock()
	defer config.mu.RUnlock()

	if key == "" {
		return ""
	}

	// 解析嵌套键,如 "proxy.servers"
	keys := strings.Split(key, ".")
	current := config.Data

	for _, k := range keys {
		if current == nil {
			return ""
		}
		
		if mapData, ok := current.(map[string]interface{}); ok {
			current = mapData[k]
		} else {
			current = nil
		}
	}

	if current == nil {
		return ""
	}

	// 转换为JSON字符串
	jsonData, err := json.Marshal(current)
	if err != nil {
		return ""
	}

	return string(jsonData)
}

// SetConfigValue 设置配置值
//export SetConfigValue
func SetConfigValue(key string, value string) int {
	config := GetConfig()
	config.mu.Lock()
	defer config.mu.Unlock()

	if key == "" {
		fmt.Printf("❌ 配置键不能为空\n")
		return 1
	}

	var data interface{}
	if err := json.Unmarshal([]byte(value), &data); err != nil {
		fmt.Printf("❌ 配置值JSON解析失败: %v\n", err)
		return 1
	}

	// 解析嵌套键
	keys := strings.Split(key, ".")
	
	// 确保数据结构存在
	if config.Data == nil {
		config.Data = make(map[string]interface{})
	}

	current := config.Data
	for i, k := range keys {
		if i == len(keys)-1 {
			// 最后一级键，直接设置值
			if mapData, ok := current.(map[string]interface{}); ok {
				mapData[k] = data
			} else {
				fmt.Printf("❌ 无法在非字典类型中设置值: %s\n", key)
				return 1
			}
		} else {
			// 中间级键，确保结构存在
			if mapData, ok := current.(map[string]interface{}); ok {
				if _, exists := mapData[k]; !exists {
					mapData[k] = make(map[string]interface{})
				}
				current = mapData[k]
			} else {
				fmt.Printf("❌ 无法创建嵌套结构: %s\n", key)
				return 1
			}
		}
	}

	fmt.Printf("✅ 配置值设置成功: %s = %s\n", key, value)
	return 0
}

// GetAllConfig 获取所有配置
//export GetAllConfig
func GetAllConfig() string {
	config := GetConfig()
	config.mu.RLock()
	defer config.mu.RUnlock()

	if config.Data == nil {
		return "{}"
	}

	jsonData, err := json.Marshal(config.Data)
	if err != nil {
		return "{}"
	}

	return string(jsonData)
}

// GetConfigPath 获取当前配置路径
//export GetConfigPath
func GetConfigPath() string {
	config := GetConfig()
	config.mu.RLock()
	defer config.mu.RUnlock()
	return config.Path
}

// createDefaultConfig 创建默认配置
func createDefaultConfig(configPath string) int {
	defaultConfig := map[string]interface{}{
		"proxy": map[string]interface{}{
			"mode": "rule",
			"log-level": "info",
			"external-controller": "127.0.0.1:9090",
			"proxies": []interface{}{},
			"proxy-groups": []interface{}{
				map[string]interface{}{
					"name": "Auto",
					"type": "url-test",
					"url": "http://www.gstatic.com/generate_204",
					"interval": 300,
					"proxies": []interface{}{},
				},
			},
			"rules": []string{
				"DOMAIN-SUFFIX,google.com,Auto",
				"DOMAIN-SUFFIX,github.com,Auto",
				"MATCH,DIRECT",
			},
		},
		"dns": map[string]interface{}{
			"enable": true,
			"ipv6": false,
			"use-hosts": true,
			"nameservers": []string{
				"8.8.8.8",
				"1.1.1.1",
				"223.5.5.5",
			},
		},
	}

	yamlData, err := yaml.Marshal(defaultConfig)
	if err != nil {
		fmt.Printf("❌ 默认配置序列化失败: %v\n", err)
		return 1
	}

	if err := os.WriteFile(configPath, yamlData, 0644); err != nil {
		fmt.Printf("❌ 创建默认配置文件失败: %v\n", err)
		return 1
	}

	config := GetConfig()
	config.mu.Lock()
	defer config.mu.Unlock()

	config.Path = configPath
	config.Data = defaultConfig

	fmt.Printf("✅ 默认配置文件创建成功: %s\n", configPath)
	return 0
}

// ListConfigKeys 列出配置键
//export ListConfigKeys
func ListConfigKeys() string {
	config := GetConfig()
	config.mu.RLock()
	defer config.mu.RUnlock()

	if config.Data == nil {
		return "[]"
	}

	var keys []string
	for key := range config.Data {
		keys = append(keys, key)
	}

	jsonData, err := json.Marshal(keys)
	if err != nil {
		return "[]"
	}

	return string(jsonData)
}
