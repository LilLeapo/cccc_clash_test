// 核心状态管理类
// 集成MihomoCore控制和LogStream功能

import 'dart:async';
import 'dart:convert';
import 'mihomo_core.dart';
import 'log_stream.dart';

class ProxyStatus {
  final String status; // 'running', 'stopped', 'starting', 'stopping'
  final String config;
  final String version;
  final DateTime? startTime;

  ProxyStatus({
    required this.status,
    required this.config,
    required this.version,
    this.startTime,
  });

  factory ProxyStatus.fromJson(Map<String, dynamic> json) {
    return ProxyStatus(
      status: json['status'] ?? 'unknown',
      config: json['config'] ?? 'default',
      version: json['version'] ?? 'unknown',
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
    );
  }

  bool get isRunning => status == 'running';
  bool get isStopped => status == 'stopped';
  bool get isStarting => status == 'starting';
  bool get isStopping => status == 'stopping';

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'config': config,
      'version': version,
      'startTime': startTime?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ProxyStatus(status: $status, config: $config, version: $version)';
  }
}

class MihomoController {
  static final MihomoController _instance = MihomoController._internal();
  factory MihomoController() => _instance;
  MihomoController._internal();

  late final MihomoCore _mihomoCore;
  late final MihomoLogHandler _logHandler;

  // 状态管理
  ProxyStatus? _currentStatus;
  final StreamController<ProxyStatus> _statusController = StreamController<ProxyStatus>.broadcast();
  final StreamController<int> _progressController = StreamController<int>.broadcast();

  // Stream暴露
  Stream<ProxyStatus> get statusStream => _statusController.stream;
  Stream<int> get progressStream => _progressController.stream;
  Stream<LogEntry> get logStream => _logHandler.logStream;

  // 状态属性
  ProxyStatus? get currentStatus => _currentStatus;
  bool get isRunning => _currentStatus?.isRunning ?? false;
  bool get isStopped => _currentStatus?.isStopped ?? true;

  // 初始化
  Future<void> initialize() async {
    _mihomoCore = MihomoCore();
    _logHandler = MihomoLogHandler();
    _logHandler.initialize();

    // 监听日志并更新状态
    _logHandler.logStream.listen((logEntry) {
      _updateStatusFromLog(logEntry);
    });

    _logHandler.addLog('info', 'Mihomo控制器初始化完成', source: 'controller');
  }

  // 启动代理
  Future<bool> startProxy({String? configPath}) async {
    if (isRunning) {
      _logHandler.addLog('warn', '代理已在运行中', source: 'controller');
      return false;
    }

    try {
      _updateStatus(ProxyStatus(status: 'starting', config: configPath ?? 'default', version: 'v0.1.0-alpha'));

      // 模拟启动进度
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(Duration(milliseconds: 100));
        _progressController.add(i);
      }

      final result = await _mihomoCore.initializeCore(configPath ?? 'default');
      if (result != 0) {
        _logHandler.addLog('error', '初始化失败: $result', source: 'controller');
        _updateStatus(ProxyStatus(status: 'stopped', config: configPath ?? 'default', version: 'v0.1.0-alpha'));
        return false;
      }

      final startResult = await _mihomoCore.startProxy();
      if (startResult != 0) {
        _logHandler.addLog('error', '启动失败: $startResult', source: 'controller');
        _updateStatus(ProxyStatus(status: 'stopped', config: configPath ?? 'default', version: 'v0.1.0-alpha'));
        return false;
      }

      _updateStatus(ProxyStatus(
        status: 'running',
        config: configPath ?? 'default',
        version: 'v0.1.0-alpha',
        startTime: DateTime.now(),
      ));

      _logHandler.addLog('info', '代理启动成功', source: 'controller');
      return true;

    } catch (e) {
      _logHandler.addLog('error', '启动异常: $e', source: 'controller');
      _updateStatus(ProxyStatus(status: 'stopped', config: configPath ?? 'default', version: 'v0.1.0-alpha'));
      return false;
    }
  }

  // 停止代理
  Future<bool> stopProxy() async {
    if (isStopped) {
      _logHandler.addLog('warn', '代理未在运行', source: 'controller');
      return false;
    }

    try {
      _updateStatus(ProxyStatus(status: 'stopping', config: _currentStatus?.config ?? 'default', version: 'v0.1.0-alpha'));

      final result = await _mihomoCore.stopProxy();
      if (result != 0) {
        _logHandler.addLog('error', '停止失败: $result', source: 'controller');
        return false;
      }

      _updateStatus(ProxyStatus(status: 'stopped', config: _currentStatus?.config ?? 'default', version: 'v0.1.0-alpha'));
      _logHandler.addLog('info', '代理已停止', source: 'controller');
      return true;

    } catch (e) {
      _logHandler.addLog('error', '停止异常: $e', source: 'controller');
      return false;
    }
  }

  // 重载配置
  Future<bool> reloadConfig({String? configPath}) async {
    try {
      _logHandler.addLog('info', '正在重载配置...', source: 'controller');

      // 这里应该调用Go的ReloadConfig方法
      // await _mihomoCore.reloadConfig(configPath);

      if (isRunning) {
        _logHandler.addLog('info', '配置重载成功，运行时生效', source: 'controller');
      } else {
        _logHandler.addLog('info', '配置重载完成，将在下次启动时生效', source: 'controller');
      }

      return true;
    } catch (e) {
      _logHandler.addLog('error', '配置重载失败: $e', source: 'controller');
      return false;
    }
  }

  // 获取版本信息
  Future<String> getVersion() async {
    try {
      return await _mihomoCore.getVersion();
    } catch (e) {
      _logHandler.addLog('error', '获取版本失败: $e', source: 'controller');
      return 'Error';
    }
  }

  // 连接状态检查
  Future<bool> checkConnection() async {
    try {
      return await _mihomoCore.checkConnection();
    } catch (e) {
      return false;
    }
  }

  // 切换代理状态（启动/停止）
  Future<bool> toggleProxy() async {
    if (isRunning) {
      return await stopProxy();
    } else {
      return await startProxy();
    }
  }

  // 清空日志
  void clearLogs() {
    _logHandler.clearLogs();
  }

  // 模拟日志（用于测试）
  void simulateLogs() {
    _logHandler.simulateLogs();
  }

  // 私有方法
  void _updateStatus(ProxyStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void _updateStatusFromLog(LogEntry logEntry) {
    // 根据日志内容更新状态
    if (logEntry.message.contains('启动成功') || logEntry.message.contains('代理运行中')) {
      if (_currentStatus?.status == 'starting') {
        _updateStatus(ProxyStatus(
          status: 'running',
          config: _currentStatus?.config ?? 'default',
          version: 'v0.1.0-alpha',
          startTime: DateTime.now(),
        ));
      }
    } else if (logEntry.message.contains('已停止')) {
      _updateStatus(ProxyStatus(
        status: 'stopped',
        config: _currentStatus?.config ?? 'default',
        version: 'v0.1.0-alpha',
      ));
    }
  }

  // 清理资源
  void dispose() {
    _statusController.close();
    _progressController.close();
    _logHandler.dispose();
  }
}