// config.go - 配置管理模块
// 支持YAML配置文件解析、验证、转换和持久化

package main

import (
	"C"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"gopkg.in/yaml.v3"
)

// 配置数据结构
type Config struct {
	Version     string            `yaml:"version" json:"version"`
	Proxy       ProxyConfig       `yaml:"proxy" json:"proxy"`
	DNS         DNSConfig         `yaml:"dns" json:"dns"`
	Hosts       map[string]string `yaml:"hosts" json:"hosts"`
	Rules       []RuleConfig      `yaml:"rules" json:"rules"`
	Experimental ExperimentalConfig `yaml:"experimental" json:"experimental"`
	Metadata    MetadataConfig    `yaml:"metadata" json:"metadata"`
	Raw         string            `yaml:"-" json:"-"`
}

// 代理配置
type ProxyConfig struct {
	Mode       string            `yaml:"mode" json:"mode"`
	HTTPProxy  string            `yaml:"http-proxy" json:"http_proxy"`
	SOCKSProxy string            `yaml:"socks-proxy" json:"socks_proxy"`
	AllowLAN   bool              `yaml:"allow-lan" json:"allow_lan"`
	BindAddress string           `yaml:"bind-address" json:"bind_address"`
	Servers    []ServerConfig    `yaml:"servers" json:"servers"`
	Groups     []GroupConfig     `yaml:"groups" json:"groups"`
}

// 服务器配置
type ServerConfig struct {
	Name     string `yaml:"name" json:"name"`
	Type     string `yaml:"type" json:"type"`
	Server   string `yaml:"server" json:"server"`
	Port     int    `yaml:"port" json:"port"`
	Username string `yaml:"username" json:"username"`
	Password string `yaml:"password" json:"password"`
	UUID     string `yaml:"uuid" json:"uuid"`
	Cipher   string `yaml:"cipher" json:"cipher"`
	Network  string `yaml:"network" json:"network"`
}

// 组配置
type GroupConfig struct {
	Name     string `yaml:"name" json:"name"`
	Type     string `yaml:"type" json:"type"`
	Servers  []string `yaml:"servers" json:"servers"`
	Proxies  []string `yaml:"proxies" json:"proxies"`
}

// DNS配置
type DNSConfig struct {
	Enable    bool     `yaml:"enable" json:"enable"`
	IPv6      bool     `yaml:"ipv6" json:"ipv6"`
	Enhanced  bool     `yaml:"enhanced" json:"enhanced"`
	Nameserver []string `yaml:"nameserver" json:"nameserver"`
	Fallback   []string `yaml:"fallback" json:"fallback"`
}

// 规则配置
type RuleConfig struct {
	Type  string `yaml:"type" json:"type"`
	Value string `yaml:"value" json:"value"`
}

// 实验性功能配置
type ExperimentalConfig struct {
	CacheFile      CacheFileConfig `yaml:"cache-file" json:"cache_file"`
	ClashAPI       ClashAPIConfig  `yaml:"clash-api" json:"clash_api"`
}

// 缓存文件配置
type CacheFileConfig struct {
	Enable   bool   `yaml:"enable" json:"enable"`
	Path     string `yaml:"path" json:"path"`
	CacheID  string `yaml:"cache-id" json:"cache_id"`
}

// Clash API配置
type ClashAPIConfig struct {
	Enable   bool   `yaml:"enable" json:"enable"`
	External string `yaml:"external" json:"external"`
}

// 元数据配置
type MetadataConfig struct {
	Name        string `yaml:"name" json:"name"`
	Author      string `yaml:"author" json:"author"`
	Created     string `yaml:"created" json:"created"`
	Modified    string `yaml:"modified" json:"modified"`
	Description string `yaml:"description" json:"description"`
}

// 全局配置管理
var (
	configMu        sync.RWMutex
	currentConfig   *Config
	configFilePath  string
	configModified  time.Time
)

//export ConfigLoad
// 加载YAML配置文件
func ConfigLoad(filePath string) *C.char {
	configMu.Lock()
	defer configMu.Unlock()

	if filePath == "" {
		filePath = "config.yaml"
	}

	// 检查文件是否存在
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "配置文件不存在: %s"}`, filePath))
	}

	// 读取文件
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "读取文件失败: %v"}`, err))
	}

	// 解析YAML
	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "YAML解析失败: %v"}`, err))
	}

	// 验证配置
	if err := validateConfig(&config); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "配置验证失败: %v"}`, err))
	}

	// 保存原始内容和元信息
	config.Raw = string(data)
	config.Metadata.Created = time.Now().Format(time.RFC3339)
	config.Metadata.Modified = time.Now().Format(time.RFC3339)
	if config.Metadata.Name == "" {
		config.Metadata.Name = filepath.Base(filePath)
	}

	// 更新当前配置
	currentConfig = &config
	configFilePath = filePath

	// 获取文件修改时间
	if info, err := os.Stat(filePath); err == nil {
		configModified = info.ModTime()
	}

	result := map[string]interface{}{
		"success":    true,
		"config":     config,
		"file_path":  filePath,
		"file_size":  len(data),
		"modified":   configModified.Format(time.RFC3339),
	}

	jsonData, _ := json.Marshal(result)
	return C.CString(string(jsonData))
}

//export ConfigSave
// 保存配置到YAML文件
func ConfigSave(configJSON string, filePath string) *C.char {
	configMu.Lock()
	defer configMu.Unlock()

	if filePath == "" {
		filePath = configFilePath
		if filePath == "" {
			filePath = "config.yaml"
		}
	}

	// 解析JSON配置
	var config Config
	if err := json.Unmarshal([]byte(configJSON), &config); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "JSON解析失败: %v"}`, err))
	}

	// 验证配置
	if err := validateConfig(&config); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "配置验证失败: %v"}`, err))
	}

	// 转换为YAML
	data, err := yaml.Marshal(&config)
	if err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "YAML序列化失败: %v"}`, err))
	}

	// 写入文件
	if err := ioutil.WriteFile(filePath, data, 0644); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "写入文件失败: %v"}`, err))
	}

	// 更新当前配置
	config.Raw = string(data)
	config.Metadata.Modified = time.Now().Format(time.RFC3339)
	currentConfig = &config
	configFilePath = filePath

	// 获取文件修改时间
	if info, err := os.Stat(filePath); err == nil {
		configModified = info.ModTime()
	}

	result := map[string]interface{}{
		"success":   true,
		"file_path": filePath,
		"file_size": len(data),
		"modified":  configModified.Format(time.RFC3339),
	}

	jsonData, _ := json.Marshal(result)
	return C.CString(string(jsonData))
}

//export ConfigGetCurrent
// 获取当前配置
func ConfigGetCurrent() *C.char {
	configMu.RLock()
	defer configMu.RUnlock()

	if currentConfig == nil {
		return C.CString(`{"success": false, "error": "未加载配置"}`)
	}

	// 添加状态信息
	result := map[string]interface{}{
		"success":     true,
		"config":      currentConfig,
		"file_path":   configFilePath,
		"modified":    configModified.Format(time.RFC3339),
		"has_config":  true,
	}

	jsonData, _ := json.Marshal(result)
	return C.CString(string(jsonData))
}

//export ConfigValidate
// 验证配置
func ConfigValidate(configJSON string) *C.char {
	var config Config
	if err := json.Unmarshal([]byte(configJSON), &config); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "JSON解析失败: %v"}`, err))
	}

	if err := validateConfig(&config); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "配置验证失败: %v"}`, err))
	}

	return C.CString(`{"success": true, "message": "配置验证通过"}`)
}

//export ConfigToJSON
// 将配置转换为JSON
func ConfigToJSON(configYAML string) *C.char {
	var config Config
	if err := yaml.Unmarshal([]byte(configYAML), &config); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "YAML解析失败: %v"}`, err))
	}

	jsonData, err := json.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "JSON序列化失败: %v"}`, err))
	}

	return C.CString(fmt.Sprintf(`{"success": true, "json": %s}`, string(jsonData)))
}

//export ConfigFromJSON
// 从JSON转换为配置
func ConfigFromJSON(configJSON string) *C.char {
	var config Config
	if err := json.Unmarshal([]byte(configJSON), &config); err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "JSON解析失败: %v"}`, err))
	}

	yamlData, err := yaml.Marshal(config)
	if err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "YAML序列化失败: %v"}`, err))
	}

	return C.CString(fmt.Sprintf(`{"success": true, "yaml": %s}`, string(yamlData)))
}

//export ConfigListProfiles
// 列出可用配置文件
func ConfigListProfiles(dirPath string) *C.char {
	if dirPath == "" {
		dirPath = "."
	}

	files, err := ioutil.ReadDir(dirPath)
	if err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "读取目录失败: %v"}`, err))
	}

	var profiles []map[string]interface{}
	for _, file := range files {
		if strings.HasSuffix(strings.ToLower(file.Name()), ".yaml") ||
		   strings.HasSuffix(strings.ToLower(file.Name()), ".yml") {

			filePath := filepath.Join(dirPath, file.Name())
			info, _ := os.Stat(filePath)

			profile := map[string]interface{}{
				"name":      file.Name(),
				"path":      filePath,
				"size":      file.Size(),
				"modified":  info.ModTime().Format(time.RFC3339),
				"is_file":   !file.IsDir(),
			}
			profiles = append(profiles, profile)
		}
	}

	result := map[string]interface{}{
		"success":   true,
		"directory": dirPath,
		"profiles":  profiles,
		"count":     len(profiles),
	}

	jsonData, _ := json.Marshal(result)
	return C.CString(string(jsonData))
}

// 验证配置
func validateConfig(config *Config) error {
	if config == nil {
		return fmt.Errorf("配置为空")
	}

	// 验证代理模式
	if config.Proxy.Mode != "" && config.Proxy.Mode != "Rule" &&
	   config.Proxy.Mode != "Global" && config.Proxy.Mode != "Direct" {
		return fmt.Errorf("不支持的代理模式: %s", config.Proxy.Mode)
	}

	// 验证服务器配置
	for i, server := range config.Proxy.Servers {
		if server.Name == "" {
			return fmt.Errorf("服务器配置 %d 缺少名称", i)
		}
		if server.Type == "" {
			return fmt.Errorf("服务器 %s 缺少类型", server.Name)
		}
		if server.Port <= 0 || server.Port > 65535 {
			return fmt.Errorf("服务器 %s 端口无效: %d", server.Name, server.Port)
		}
	}

	// 验证组配置
	for i, group := range config.Proxy.Groups {
		if group.Name == "" {
			return fmt.Errorf("组配置 %d 缺少名称", i)
		}
		if group.Type == "" {
			return fmt.Errorf("组 %s 缺少类型", group.Name)
		}
	}

	// 验证DNS配置
	if config.DNS.Enable {
		if len(config.DNS.Nameserver) == 0 {
			return fmt.Errorf("DNS启用时必须配置nameserver")
		}
	}

	return nil
}

//export ConfigHotReload
// 配置热重载
func ConfigHotReload() *C.char {
	configMu.Lock()
	defer configMu.Unlock()

	if configFilePath == "" {
		return C.CString(`{"success": false, "error": "未指定配置文件路径"}`)
	}

	// 检查文件是否被修改
	info, err := os.Stat(configFilePath)
	if err != nil {
		return C.CString(fmt.Sprintf(`{"success": false, "error": "无法检查文件状态: %v"}`, err))
	}

	if info.ModTime().Equal(configModified) {
		return C.CString(`{"success": true, "message": "配置文件未修改，无需重载"}`)
	}

	// 重新加载配置
	result := ConfigLoad(configFilePath)

	// 更新修改时间
	configModified = info.ModTime()

	return result
}
