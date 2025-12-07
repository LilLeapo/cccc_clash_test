import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Hive数据库服务 - 配置数据的持久化存储
class HiveService {
  static const String CONFIG_BOX = 'config';
  static const String PROXY_BOX = 'proxies';
  static const String RULE_BOX = 'rules';
  static const String STAT_BOX = 'statistics';

  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._internal();

  HiveService._internal();

  Box? _configBox;
  Box? _proxyBox;
  Box? _ruleBox;
  Box? _statBox;

  bool get isInitialized => _configBox?.isOpen == true;

  /// 初始化Hive数据库
  Future<void> initialize() async {
    try {
      // 初始化Hive Flutter
      await Hive.initFlutter();

      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/mihomo_hive');
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
      }

      // 注册适配器
      _registerAdapters();

      // 打开各个Box
      _configBox = await Hive.openBox(CONFIG_BOX, path: hiveDir.path);
      _proxyBox = await Hive.openBox(PROXY_BOX, path: hiveDir.path);
      _ruleBox = await Hive.openBox(RULE_BOX, path: hiveDir.path);
      _statBox = await Hive.openBox(STAT_BOX, path: hiveDir.path);

      print('✅ Hive数据库初始化成功');
    } catch (e) {
      print('❌ Hive数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 注册Hive适配器
  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ConfigDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProxyServerAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(RuleDataAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(StatisticsDataAdapter());
    }
  }

  // ========== 配置数据操作 ==========

  /// 保存配置
  Future<void> saveConfig(String key, Map<String, dynamic> config) async {
    if (_configBox == null) throw Exception('Hive未初始化');
    
    final configData = ConfigData()
      ..key = key
      ..data = config
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    
    await _configBox!.put(key, configData);
    print('✅ 配置保存成功: $key');
  }

  /// 获取配置
  Future<Map<String, dynamic>?> getConfig(String key) async {
    if (_configBox == null) throw Exception('Hive未初始化');
    
    final configData = _configBox!.get(key) as ConfigData?;
    return configData?.data;
  }

  /// 获取所有配置键
  Future<List<String>> getAllConfigKeys() async {
    if (_configBox == null) throw Exception('Hive未初始化');
    return _configBox!.keys.cast<String>().toList();
  }

  /// 删除配置
  Future<void> deleteConfig(String key) async {
    if (_configBox == null) throw Exception('Hive未初始化');
    await _configBox!.delete(key);
    print('✅ 配置删除成功: $key');
  }

  // ========== 代理服务器操作 ==========

  /// 保存代理服务器
  Future<void> saveProxyServer(String id, Map<String, dynamic> proxy) async {
    if (_proxyBox == null) throw Exception('Hive未初始化');
    
    final proxyData = ProxyServer()
      ..id = id
      ..data = proxy
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    
    await _proxyBox!.put(id, proxyData);
  }

  /// 获取代理服务器
  Future<Map<String, dynamic>?> getProxyServer(String id) async {
    if (_proxyBox == null) throw Exception('Hive未初始化');
    
    final proxyData = _proxyBox!.get(id) as ProxyServer?;
    return proxyData?.data;
  }

  /// 获取所有代理服务器
  Future<Map<String, Map<String, dynamic>>> getAllProxies() async {
    if (_proxyBox == null) throw Exception('Hive未初始化');
    
    final Map<String, Map<String, dynamic>> proxies = {};
    for (final key in _proxyBox!.keys) {
      final proxyData = _proxyBox!.get(key) as ProxyServer?;
      if (proxyData != null) {
        proxies[key] = proxyData.data;
      }
    }
    return proxies;
  }

  // ========== 规则数据操作 ==========

  /// 保存规则
  Future<void> saveRule(String id, Map<String, dynamic> rule) async {
    if (_ruleBox == null) throw Exception('Hive未初始化');
    
    final ruleData = RuleData()
      ..id = id
      ..data = rule
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    
    await _ruleBox!.put(id, ruleData);
  }

  /// 获取所有规则
  Future<List<Map<String, dynamic>>> getAllRules() async {
    if (_ruleBox == null) throw Exception('Hive未初始化');
    
    final List<Map<String, dynamic>> rules = [];
    for (final key in _ruleBox!.keys) {
      final ruleData = _ruleBox!.get(key) as RuleData?;
      if (ruleData != null) {
        rules.add(ruleData.data);
      }
    }
    return rules;
  }

  // ========== 统计数据操作 ==========

  /// 保存统计数据
  Future<void> saveStatistics(String date, Map<String, dynamic> stats) async {
    if (_statBox == null) throw Exception('Hive未初始化');
    
    final statData = StatisticsData()
      ..date = date
      ..data = stats
      ..createdAt = DateTime.now();
    
    await _statBox!.put(date, statData);
  }

  /// 获取统计数据
  Future<Map<String, dynamic>?> getStatistics(String date) async {
    if (_statBox == null) throw Exception('Hive未初始化');
    
    final statData = _statBox!.get(date) as StatisticsData?;
    return statData?.data;
  }

  /// 获取最近N天的统计数据
  Future<List<Map<String, dynamic>>> getRecentStatistics(int days) async {
    if (_statBox == null) throw Exception('Hive未初始化');
    
    final List<Map<String, dynamic>> stats = [];
    final keys = _statBox!.keys.cast<String>().toList()
      ..sort((a, b) => b.compareTo(a)); // 最新的在前
    
    for (final key in keys.take(days)) {
      final statData = _statBox!.get(key) as StatisticsData?;
      if (statData != null) {
        stats.add({
          'date': key,
          ...statData.data,
        });
      }
    }
    return stats;
  }

  // ========== 数据加密 ==========

  /// 加密数据
  String encryptData(String data, String key) {
    final bytes = utf8.encode(data);
    final keyBytes = utf8.encode(key.padRight(32, '0').substring(0, 32));
    
    // 简单的XOR加密（实际项目中应使用更强的加密算法）
    final encrypted = BytesBuilder();
    for (int i = 0; i < bytes.length; i++) {
      encrypted.addByte(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted.toBytes());
  }

  /// 解密数据
  String decryptData(String encryptedData, String key) {
    try {
      final encryptedBytes = base64.decode(encryptedData);
      final keyBytes = utf8.encode(key.padRight(32, '0').substring(0, 32));
      
      final decrypted = BytesBuilder();
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.addByte(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted.toBytes());
    } catch (e) {
      print('❌ 数据解密失败: $e');
      return '';
    }
  }

  // ========== 数据库维护 ==========

  /// 清理过期数据
  Future<void> cleanupExpiredData(int daysToKeep) async {
    if (_statBox == null) return;
    
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final keysToDelete = <String>[];
    
    for (final key in _statBox!.keys) {
      try {
        final date = DateTime.parse(key.toString());
        if (date.isBefore(cutoffDate)) {
          keysToDelete.add(key.toString());
        }
      } catch (e) {
        // 忽略无效日期格式
      }
    }
    
    for (final key in keysToDelete) {
      await _statBox!.delete(key);
    }
    
    print('✅ 清理过期数据完成，删除${keysToDelete.length}条记录');
  }

  /// 压缩数据库
  Future<void> compactDatabase() async {
    if (_configBox == null) return;
    
    await _configBox!.compact();
    await _proxyBox!.compact();
    await _ruleBox!.compact();
    await _statBox!.compact();
    
    print('✅ 数据库压缩完成');
  }

  /// 关闭数据库
  Future<void> close() async {
    await _configBox?.close();
    await _proxyBox?.close();
    await _ruleBox?.close();
    await _statBox?.close();
    
    print('✅ Hive数据库已关闭');
  }
}

// ========== 数据模型 ==========

/// 配置数据模型
@HiveType(typeId: 0)
class ConfigData extends HiveObject {
  @HiveField(0)
  String? key;

  @HiveField(1)
  Map<String, dynamic>? data;

  @HiveField(2)
  DateTime? createdAt;

  @HiveField(3)
  DateTime? updatedAt;
}

/// 代理服务器模型
@HiveType(typeId: 1)
class ProxyServer extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  Map<String, dynamic>? data;

  @HiveField(2)
  DateTime? createdAt;

  @HiveField(3)
  DateTime? updatedAt;
}

/// 规则数据模型
@HiveType(typeId: 2)
class RuleData extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  Map<String, dynamic>? data;

  @HiveField(2)
  DateTime? createdAt;

  @HiveField(3)
  DateTime? updatedAt;
}

/// 统计数据模型
@HiveType(typeId: 3)
class StatisticsData extends HiveObject {
  @HiveField(0)
  String? date;

  @HiveField(1)
  Map<String, dynamic>? data;

  @HiveField(2)
  DateTime? createdAt;
}

/// Hive适配器
class ConfigDataAdapter extends TypeAdapter<ConfigData> {
  @override
  final typeId = 0;

  @override
  ConfigData read(BinaryReader reader) {
    final obj = ConfigData();
    obj.key = reader.readString();
    obj.data = reader.readMap().cast<String, dynamic>();
    obj.createdAt = reader.readDateTime();
    obj.updatedAt = reader.readDateTime();
    return obj;
  }

  @override
  void write(BinaryWriter writer, ConfigData obj) {
    writer.writeString(obj.key ?? '');
    writer.writeMap(obj.data ?? {});
    writer.writeDateTime(obj.createdAt);
    writer.writeDateTime(obj.updatedAt);
  }
}

class ProxyServerAdapter extends TypeAdapter<ProxyServer> {
  @override
  final typeId = 1;

  @override
  ProxyServer read(BinaryReader reader) {
    final obj = ProxyServer();
    obj.id = reader.readString();
    obj.data = reader.readMap().cast<String, dynamic>();
    obj.createdAt = reader.readDateTime();
    obj.updatedAt = reader.readDateTime();
    return obj;
  }

  @override
  void write(BinaryWriter writer, ProxyServer obj) {
    writer.writeString(obj.id ?? '');
    writer.writeMap(obj.data ?? {});
    writer.writeDateTime(obj.createdAt);
    writer.writeDateTime(obj.updatedAt);
  }
}

class RuleDataAdapter extends TypeAdapter<RuleData> {
  @override
  final typeId = 2;

  @override
  RuleData read(BinaryReader reader) {
    final obj = RuleData();
    obj.id = reader.readString();
    obj.data = reader.readMap().cast<String, dynamic>();
    obj.createdAt = reader.readDateTime();
    obj.updatedAt = reader.readDateTime();
    return obj;
  }

  @override
  void write(BinaryWriter writer, RuleData obj) {
    writer.writeString(obj.id ?? '');
    writer.writeMap(obj.data ?? {});
    writer.writeDateTime(obj.createdAt);
    writer.writeDateTime(obj.updatedAt);
  }
}

class StatisticsDataAdapter extends TypeAdapter<StatisticsData> {
  @override
  final typeId = 3;

  @override
  StatisticsData read(BinaryReader reader) {
    final obj = StatisticsData();
    obj.date = reader.readString();
    obj.data = reader.readMap().cast<String, dynamic>();
    obj.createdAt = reader.readDateTime();
    return obj;
  }

  @override
  void write(BinaryWriter writer, StatisticsData obj) {
    writer.writeString(obj.date ?? '');
    writer.writeMap(obj.data ?? {});
    writer.writeDateTime(obj.createdAt);
  }
}
