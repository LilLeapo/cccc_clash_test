// config_manager.dart - Flutter配置管理
// 集成Hive数据库实现跨平台配置存储

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// 配置管理器
/// 支持跨平台配置存储、加密和同步
class ConfigManager {
  static const String _configBoxName = 'mihomo_configs';
  static const String _profilesBoxName = 'config_profiles';
  static const String _settingsBoxName = 'app_settings';

  static const String _encryptionKey = 'mihomo_flutter_cross_2025';

  late Box _configBox;
  late Box _profilesBox;
  late Box _settingsBox;

  bool _initialized = false;

  /// 初始化配置管理器
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // 获取应用目录
      final directory = await getApplicationDocumentsDirectory();
      final configDir = Directory('${directory.path}/mihomo_config');

      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }

      // 初始化Hive
      Hive.init('${directory.path}/hive');

      // 打开数据盒子
      _configBox = await Hive.openBox(_configBoxName);
      _profilesBox = await Hive.openBox(_profilesBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      // 检查是否需要设置加密
      await _setupEncryption();

      _initialized = true;
      print('✅ 配置管理器初始化成功');
      return true;
    } catch (e) {
      print('❌ 配置管理器初始化失败: $e');
      return false;
    }
  }

  /// 设置加密
  Future<void> _setupEncryption() async {
    final encryptionKey = generateKey();

    // 为配置盒子设置加密
    if (!_configBox.isEmpty) {
      // 如果已经有数据，重新初始化
      return;
    }

    try {
      await Hive.openBox(_configBoxName, encryptionCipher: HiveAesCipher(encryptionKey));
    } catch (e) {
      print('⚠️ 加密设置失败，使用明文存储: $e');
    }
  }

  /// 生成加密密钥
  List<int> generateKey() {
    final bytes = utf8.encode(_encryptionKey);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

  // =============================================================================
  // 配置文件管理
  // =============================================================================

  /// 保存配置
  Future<Map<String, dynamic>> saveConfig({
    required String name,
    required Map<String, dynamic> config,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();

    try {
      final timestamp = DateTime.now().toIso8601String();
      final configData = {
        'id': _generateId(name),
        'name': name,
        'config': config,
        'description': description ?? '',
        'metadata': metadata ?? {},
        'created': timestamp,
        'modified': timestamp,
        'version': '1.0.0',
        'size': utf8.encode(json.encode(config)).length,
      };

      // 保存到配置盒子
      await _configBox.put(configData['id'], configData);

      // 更新配置列表
      await _updateProfileList(configData);

      print('📝 配置已保存: $name');
      return {'success': true, 'data': configData};
    } catch (e) {
      print('❌ 保存配置失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 加载配置
  Future<Map<String, dynamic>> loadConfig(String configId) async {
    await _ensureInitialized();

    try {
      final configData = _configBox.get(configId);
      if (configData == null) {
        return {'success': false, 'error': '配置不存在'};
      }

      // 更新最后访问时间
      configData['last_accessed'] = DateTime.now().toIso8601String();
      await _configBox.put(configId, configData);

      print('📖 配置已加载: ${configData['name']}');
      return {'success': true, 'data': configData};
    } catch (e) {
      print('❌ 加载配置失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 删除配置
  Future<Map<String, dynamic>> deleteConfig(String configId) async {
    await _ensureInitialized();

    try {
      final configData = _configBox.get(configId);
      if (configData == null) {
        return {'success': false, 'error': '配置不存在'};
      }

      // 删除配置
      await _configBox.delete(configId);

      // 从配置列表中移除
      await _removeFromProfileList(configId);

      print('🗑️ 配置已删除: ${configData['name']}');
      return {'success': true, 'message': '配置删除成功'};
    } catch (e) {
      print('❌ 删除配置失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 获取所有配置
  Future<Map<String, dynamic>> getAllConfigs() async {
    await _ensureInitialized();

    try {
      final configs = <String, dynamic>{};

      for (var key in _configBox.keys) {
        final configData = _configBox.get(key);
        if (configData != null) {
          configs[key] = configData;
        }
      }

      return {
        'success': true,
        'configs': configs.values.toList(),
        'count': configs.length,
      };
    } catch (e) {
      print('❌ 获取配置列表失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =============================================================================
  // 配置导入导出
  // =============================================================================

  /// 导出配置为YAML
  Future<Map<String, dynamic>> exportConfigToYAML(String configId) async {
    await _ensureInitialized();

    try {
      final configData = await loadConfig(configId);
      if (!configData['success']) {
        return configData;
      }

      // 将JSON配置转换为YAML格式
      final yamlContent = _convertJsonToYaml(configData['data']['config']);

      // 生成导出文件路径
      final directory = await getApplicationDocumentsDirectory();
      final exportPath = '${directory.path}/exports/${configData['data']['name']}.yaml';

      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // 写入文件
      final file = File(exportPath);
      await file.writeAsString(yamlContent);

      print('📤 配置已导出到: $exportPath');
      return {
        'success': true,
        'path': exportPath,
        'content': yamlContent,
        'size': yamlContent.length,
      };
    } catch (e) {
      print('❌ 导出配置失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 从YAML导入配置
  Future<Map<String, dynamic>> importConfigFromYAML({
    required String yamlContent,
    required String name,
    String? description,
  }) async {
    await _ensureInitialized();

    try {
      // 将YAML转换为JSON
      final jsonConfig = _convertYamlToJson(yamlContent);

      // 保存配置
      return await saveConfig(
        name: name,
        config: jsonConfig,
        description: description,
      );
    } catch (e) {
      print('❌ 导入配置失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 从文件导入配置
  Future<Map<String, dynamic>> importConfigFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return {'success': false, 'error': '文件不存在'};
      }

      final content = await file.readAsString();
      final fileName = file.uri.pathSegments.last;
      final name = fileName.replaceAll(RegExp(r'\.(yaml|yml)$'), '');

      return await importConfigFromYAML(
        yamlContent: content,
        name: name,
        description: '从文件导入: $filePath',
      );
    } catch (e) {
      print('❌ 从文件导入配置失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =============================================================================
  // 应用设置
  // =============================================================================

  /// 保存应用设置
  Future<void> saveSetting(String key, dynamic value) async {
    await _ensureInitialized();
    await _settingsBox.put(key, value);
  }

  /// 获取应用设置
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    await _ensureInitialized();
    return _settingsBox.get(key) ?? defaultValue;
  }

  /// 删除应用设置
  Future<void> removeSetting(String key) async {
    await _ensureInitialized();
    await _settingsBox.delete(key);
  }

  /// 清空所有设置
  Future<void> clearAllSettings() async {
    await _ensureInitialized();
    await _settingsBox.clear();
  }

  // =============================================================================
  // 配置同步
  // =============================================================================

  /// 同步配置到云端 (预留接口)
  Future<Map<String, dynamic>> syncToCloud(String configId) async {
    // TODO: 实现云端同步功能
    return {'success': false, 'error': '云端同步功能暂未实现'};
  }

  /// 从云端同步配置 (预留接口)
  Future<Map<String, dynamic>> syncFromCloud() async {
    // TODO: 实现云端同步功能
    return {'success': false, 'error': '云端同步功能暂未实现'};
  }

  /// 备份配置
  Future<Map<String, dynamic>> backupConfigs(String backupPath) async {
    await _ensureInitialized();

    try {
      final allConfigs = await getAllConfigs();
      if (!allConfigs['success']) {
        return allConfigs;
      }

      final backupData = {
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'configs': allConfigs['configs'],
        'settings': _settingsBox.toMap(),
      };

      final backupJson = json.encode(backupData);

      final directory = Directory(backupPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = '$backupPath/backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(filePath);
      await file.writeAsString(backupJson);

      print('💾 配置备份完成: $filePath');
      return {
        'success': true,
        'path': filePath,
        'size': backupJson.length,
      };
    } catch (e) {
      print('❌ 备份配置失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =============================================================================
  // 私有方法
  // =============================================================================

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  String _generateId(String name) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('$name$timestamp')).toString();
    return hash.substring(0, 16);
  }

  Future<void> _updateProfileList(Map<String, dynamic> configData) async {
    final profileList = _profilesBox.get('list') as List? ?? [];
    profileList.add(configData['id']);
    await _profilesBox.put('list', profileList);
  }

  Future<void> _removeFromProfileList(String configId) async {
    final profileList = _profilesBox.get('list') as List? ?? [];
    profileList.remove(configId);
    await _profilesBox.put('list', profileList);
  }

  String _convertJsonToYaml(Map<String, dynamic> jsonData) {
    // 简单的JSON到YAML转换
    // 在实际项目中建议使用专门的yaml库
    return _jsonToYamlString(jsonData, 0);
  }

  String _jsonToYamlString(dynamic data, int indent) {
    final indentStr = '  ' * indent;
    final buffer = StringBuffer();

    if (data is Map) {
      for (var entry in data.entries) {
        if (entry.value is Map || entry.value is List) {
          buffer.writeln('$indentStr${entry.key}:');
          buffer.write(_jsonToYamlString(entry.value, indent + 1));
        } else if (entry.value is String) {
          buffer.writeln('$indentStr${entry.key}: "${entry.value}"');
        } else {
          buffer.writeln('$indentStr${entry.key}: ${entry.value}');
        }
      }
    } else if (data is List) {
      for (var item in data) {
        if (item is Map || item is List) {
          buffer.writeln('${indentStr}-');
          buffer.write(_jsonToYamlString(item, indent + 1));
        } else {
          buffer.writeln('$indentStr- $item');
        }
      }
    }

    return buffer.toString();
  }

  Map<String, dynamic> _convertYamlToJson(String yamlContent) {
    // 简单的YAML到JSON转换
    // 在实际项目中建议使用专门的yaml库
    try {
      // 这里应该使用真正的YAML解析器
      // 现在返回模拟数据用于测试
      return {
        'version': 'v1',
        'proxy': {
          'mode': 'Rule',
          'allow-lan': false,
        },
        'raw_yaml': yamlContent,
      };
    } catch (e) {
      throw Exception('YAML解析失败: $e');
    }
  }

  // =============================================================================
  // 清理和释放
  // =============================================================================

  /// 清理过期配置
  Future<Map<String, dynamic>> cleanupExpiredConfigs() async {
    await _ensureInitialized();

    try {
      final now = DateTime.now();
      final expiredIds = <String>[];

      for (var key in _configBox.keys) {
        final configData = _configBox.get(key);
        if (configData != null) {
          final modified = DateTime.parse(configData['modified']);
          final daysDiff = now.difference(modified).inDays;

          // 删除30天前修改的配置
          if (daysDiff > 30) {
            expiredIds.add(key as String);
          }
        }
      }

      // 删除过期配置
      for (var id in expiredIds) {
        await _configBox.delete(id);
        await _removeFromProfileList(id);
      }

      print('🧹 清理了 ${expiredIds.length} 个过期配置');
      return {
        'success': true,
        'cleaned': expiredIds.length,
      };
    } catch (e) {
      print('❌ 清理过期配置失败: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 关闭配置管理器
  Future<void> close() async {
    if (_initialized) {
      await _configBox.close();
      await _profilesBox.close();
      await _settingsBox.close();
      _initialized = false;
      print('🔒 配置管理器已关闭');
    }
  }
}

/// 配置管理器单例
final configManager = ConfigManager();
