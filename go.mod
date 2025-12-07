module mihomo_flutter_cross

go 1.21

// 核心依赖
require gopkg.in/yaml.v3 v3.0.1

// Go Mobile支持
require golang.org/x/mobile v0.0.0-20231108141210-1e8b84ce92f3

// 用于跨平台编译
require (
	golang.org/x/sys v0.15.0
	golang.org/x/crypto v0.15.0
)
