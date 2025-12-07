import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'hive_service.dart';

/// 配置管理器 - 统一管理Go和Dart之间的配置同步
class ConfigManager {
  static ConfigManager? _instance;
  static ConfigManager get instance => _instance ??= ConfigManager._internal();

  ConfigManager._internal();

  final HiveService _hiveService = HiveService.instance;
  MethodChannel? _methodChannel;

  bool get isInitialized => _hiveService.isInitialized;

  /// 初始化配置管理器
  Future<void> initialize() async {
    try {
      // 初始化Hive数据库
      await _hiveService.initialize();

      // 初始化MethodChannel
      _methodChannel = const MethodChannel('mihomo_flutter/config');
      
      print('✅ 配置管理器初始化成功');
    } catch (e) {
      print('❌ 配置管理器初始化失败: $e');
      rethrow;
    }
  }

  // ========== 配置同步操作 ==========

  /// 从Go侧加载配置到Hive
  Future<Map<String, dynamic>?> loadConfigFromGo(String configPath) async {
    try {
      // 调用Go侧的LoadConfigFile函数
      final result = await _methodChannel?.invokeMethod('LoadConfigFile', {
        'configPath': configPath,
      });

      if (result == 0) {
        // 成功加载Go配置，现在获取所有配置数据
        final allConfigJson = await _methodChannel?.invokeMethod('GetAllConfig');
        final allConfig = json.decode(allConfigJson as String);

        // 保存到Hive数据库
        await _hiveService.saveConfig('current', allConfig as Map<String, dynamic>);

        print('✅ 配置从Go同步到Hive成功');
        return allConfig;
      } else {
        print('❌ 从Go加载配置失败');
        return null;
      }
    } catch (e) {
      print('❌ 配置同步失败: $e');
      return null;
    }
  }

  /// 将配置保存到Go侧
  Future<bool> saveConfigToGo(String configPath, Map<String, dynamic> config) async {
    try {
      final configJson = json.encode(config);
      
      final result = await _methodChannel?.invokeMethod('SaveConfigFile', {
        'configPath': configPath,
        'configData': configJson,
      });

      final success = result == 0;
      if (success) {
        print('✅ 配置保存到Go成功');
      } else {
        print('❌ 配置保存到Go失败');
      }

      return success;
    } catch (e) {
      print('❌ 保存配置到Go失败: $e');
      return false;
    }
  }

  /// 更新配置值并同步到Go
  Future<bool> updateConfigValue(String key, dynamic value) async {
    try {
      // 更新Hive中的配置
      final currentConfig = await _hiveService.getConfig('current') ?? {};
      
      // 更新值
      final keys = key.split('.');
      Map<String, dynamic> current = currentConfig;
      
      for (int i = 0; i < keys.length - 1; i++) {
        final k = keys[i];
        if (!current.containsKey(k) || current[k] is! Map<String, dynamic>) {
          current[k] = <String, dynamic>{};
        }
        current = current[k];
      }
      
      current[keys.last] = value;
      
      // 保存到Hive
      await _hiveService.saveConfig('current', currentConfig);

      // 同步到Go
      final valueJson = json.encode(value);
      final result = await _methodChannel?.invokeMethod('SetConfigValue', {
        'key': key,
        'value': valueJson,
      });

      final success = result == 0;
      if (success) {
        print('✅ 配置值更新成功: $key = $value');
      } else {
        print('❌ 配置值更新失败');
      }

      return success;
    } catch (e) {
      print('❌ 更新配置值失败: $e');
      return false;
    }
  }

  /// 获取配置值
  Future<T?> getConfigValue<T>(String key) async {
    try {
      // 先从Go侧获取
      final goValue = await _methodChannel?.invokeMethod('GetConfigValue', {
        'key': key,
      });

      if (goValue != null && goValue is String && goValue.isNotEmpty) {
        return json.decode(goValue) as T?;
      }

      // 如果Go侧没有，则从Hive获取
      final currentConfig = await _hiveService.getConfig('current');
      if (currentConfig == null) return null;

      // 解析嵌套键
      final keys = key.split('.');
      dynamic current = currentConfig;
      
      for (final k in keys) {
        if (current is Map<String, dynamic> && current.containsKey(k)) {
          current = current[k];
        } else {
          return null;
        }
      }

      return current as T?;
    } catch (e) {
      print('❌ 获取配置值失败: $e');
      return null;
    }
  }

  // ========== 配置文件操作 ==========

  /// 创建默认配置
  Future<bool> createDefaultConfig() async {
    try {
      final defaultConfig = {
        'proxy': {
          'mode': 'rule',
          'log-level': 'info',
          'external-controller': '127.0.0.1:9090',
          'proxies': [],
          'proxy-groups': [
            {
              'name': 'Auto',
              'type': 'url-test',
              'url': 'http://www.gstatic.com/generate_204',
              'interval': 300,
              'proxies': [],
            },
          ],
          'rules': [
            'DOMAIN-SUFFIX,google.com,Auto',
            'DOMAIN-SUFFIX,github.com,Auto',
            'MATCH,DIRECT',
          ],
        },
        'dns': {
          'enable': true,
          'ipv6': false,
          'use-hosts': true,
          'nameservers': [
            '8.8.8.8',
            '1.1.1.1',
            '223.5.5.5',
          ],
        },
      };

      // 保存到Hive
      await _hiveService.saveConfig('default', defaultConfig);

      // 保存到Go
      final success = await saveConfigToGo('configs/default.yaml', defaultConfig);

      return success;
    } catch (e) {
      print('❌ 创建默认配置失败: $e');
      return false;
    }
  }

  /// 导入配置文件
  Future<Map<String, dynamic>?> importConfig(String yamlContent, String name) async {
    try {
      // 先验证YAML内容（这里简化处理，实际应该用yaml包解析）
      final config = _parseYamlContent(yamlContent);
      if (config == null) {
        print('❌ YAML内容格式错误');
        return null;
      }

      // 保存到Hive
      await _hiveService.saveConfig(name, config);

      // 保存到Go
      final configPath = 'configs/$name.yaml';
      final success = await saveConfigToGo(configPath, config);

      if (success) {
        print('✅ 配置导入成功: $name');
        return config;
      }

      return null;
    } catch (e) {
      print('❌ 配置导入失败: $e');
      return null;
    }
  }

  /// 导出配置
  Future<String?> exportConfig(String name) async {
    try {
      final config = await _hiveService.getConfig(name);
      if (config == null) {
        print('❌ 配置不存在: $name');
        return null;
      }

      // 这里应该调用Go侧的方法来生成YAML格式
      // 简化处理，返回JSON格式
      return json.encode(config);
    } catch (e) {
      print('❌ 配置导出失败: $e');
      return null;
    }
  }

  /// 获取所有配置列表
  Future<List<String>> getConfigList() async {
    final keys = await _hiveService.getAllConfigKeys();
    return keys.where((key) => key != 'current').toList();
  }

  /// 删除配置
  Future<bool> deleteConfig(String name) async {
    try {
      await _hiveService.deleteConfig(name);
      print('✅ 配置删除成功: $name');
      return true;
    } catch (e) {
      print('❌ 配置删除失败: $e');
      return false;
    }
  }

  // ========== 辅助方法 ==========

  /// 简单的YAML解析（实际项目应使用yaml包）
  Map<String, dynamic>? _parseYamlContent(String content) {
    try {
      // 这里简化处理，假设输入的是有效的JSON
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      // 尝试简单的YAML到JSON转换
      return _simpleYamlToJson(content);
    }
  }

  /// 简单YAML到JSON转换
  Map<String, dynamic>? _simpleYamlToJson(String yamlContent) {
    try {
      final lines = yamlContent.split('\n');
      final result = <String, dynamic>{};
      final stack = <Map<String, dynamic>>[result];
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        
        if (trimmed.endsWith(':')) {
          final key = trimmed.substring(0, trimmed.length - 1).trim();
          final value = <String, dynamic>{};
          stack.last[key] = value;
          stack.add(value);
        } else if (trimmed.contains(':')) {
          final parts = trimmed.split(':');
          final key = parts[0].trim();
          final value = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
          stack.last[key] = _parseValue(value);
        } else if (trimmed == '-') {
          // 数组项（简化处理）
          if (!stack.last.containsKey('items')) {
            stack.last['items'] = [];
          }
          stack.last['items'].add({});
        }
      }
      
      return result;
    } catch (e) {
      return null;
    }
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    if (value == 'null') return null;
    
    final number = int.tryParse(value);
    if (number != null) return number;
    
    final doubleNum = double.tryParse(value);
    if (doubleNum != null) return doubleNum;
    
    return value;
  }

  // ========== 配置验证 ==========

  /// 验证配置完整性
  Future<Map<String, List<String>>> validateConfig(String name) async {
    final config = await _hiveService.getConfig(name);
    final errors = <String, List<String>>{};
    
    if (config == null) {
      errors['general'] = ['配置不存在'];
      return errors;
    }
    
    // 验证代理配置
    if (!config.containsKey('proxy')) {
      errors['proxy'] = ['缺少proxy配置'];
    } else {
      final proxy = config['proxy'] as Map<String, dynamic>;
      if (!proxy.containsKey('mode')) {
        errors['proxy'] = ['缺少proxy.mode配置'];
      }
      if (!proxy.containsKey('rules') || (proxy['rules'] as List).isEmpty) {
        errors['proxy'] = ['缺少proxy.rules配置或规则为空'];
      }
    }
    
    // 验证DNS配置
    if (!config.containsKey('dns')) {
      errors['dns'] = ['缺少dns配置'];
    } else {
      final dns = config['dns'] as Map<String, dynamic>;
      if (!dns.containsKey('nameservers') || (dns['nameservers'] as List).isEmpty) {
        errors['dns'] = ['缺少dns.nameservers配置或DNS服务器为空'];
      }
    }
    
    return errors;
  }

  // ========== 实时监听 ==========

  /// 监听配置变化
  Stream<Map<String, dynamic>> watchConfig(String name) async* {
    while (true) {
      final config = await _hiveService.getConfig(name);
      if (config != null) {
        yield config;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
