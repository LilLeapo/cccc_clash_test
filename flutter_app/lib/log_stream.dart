// 日志流处理模块
// 处理从Go内核传出的日志，并转换为Flutter Stream

import 'dart:async';
import 'dart:ffi';
import 'platform/desktop/ffi_bridge.dart';

class LogEntry {
  final String level;
  final String message;
  final DateTime timestamp;
  final String source;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.source = 'mihomo',
  });

  factory LogEntry.fromGoLog(String level, String message) {
    return LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final icon = _getLevelIcon(level);
    return '$timeStr $icon [$level] $message';
  }

  String _getLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'info':
        return 'ℹ️';
      case 'warn':
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      case 'debug':
        return '🔍';
      case 'error':
        return '🔴';
      default:
        return '📝';
    }
  }
}

class LogStream {
  static final LogStream _instance = LogStream._internal();
  factory LogStream() => _instance;
  LogStream._internal();

  // StreamController 用于管理日志流
  final StreamController<LogEntry> _controller = StreamController<LogEntry>.broadcast();

  // 公开的Stream
  Stream<LogEntry> get stream => _controller.stream;

  // 日志缓冲区
  final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000;

  // 添加日志
  void addLog(String level, String message, {String source = 'mihomo'}) {
    final log = LogEntry(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      source: source,
    );

    _logs.add(log);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    _controller.add(log);
    print(log.toString());
  }

  // 获取最近N条日志
  List<LogEntry> getRecentLogs([int count = 50]) {
    final start = _logs.length - count;
    if (start < 0) {
      return List.from(_logs);
    }
    return _logs.sublist(start);
  }

  // 清空日志
  void clearLogs() {
    _logs.clear();
  }

  // 按级别过滤日志
  List<LogEntry> getLogsByLevel(String level) {
    return _logs.where((log) => log.level == level).toList();
  }

  // 按源过滤日志
  List<LogEntry> getLogsBySource(String source) {
    return _logs.where((log) => log.source == source).toList();
  }

  // 关闭Stream
  void dispose() {
    _controller.close();
  }
}

// 日志级别枚举
enum LogLevel {
  debug('debug'),
  info('info'),
  warn('warn'),
  error('error');

  const LogLevel(this.value);
  final String value;

  static LogLevel fromString(String level) {
    try {
      return LogLevel.values.firstWhere((e) => e.value == level.toLowerCase());
    } catch (e) {
      return LogLevel.info;
    }
  }
}

// 与FFI桥接集成的日志处理
class MihomoLogHandler {
  static final MihomoLogHandler _instance = MihomoLogHandler._internal();
  factory MihomoLogHandler() => _instance;
  MihomoLogHandler._internal();

  late final LogStream _logStream;

  void initialize() {
    _logStream = LogStream();
    _logStream.addLog('info', '日志系统初始化完成', source: 'flutter');
  }

  // 处理来自Go内核的日志回调
  void handleGoLog(String level, String message) {
    _logStream.addLog(level, message, source: 'go');
  }

  // 获取日志Stream
  Stream<LogEntry> get logStream => _logStream.stream;

  // 获取最近的日志
  List<LogEntry> get recentLogs => _logStream.getRecentLogs();

  // 清空日志
  void clearLogs() {
    _logStream.clearLogs();
  }

  // 模拟一些示例日志
  void simulateLogs() {
    final logs = [
      ('info', 'Mihomo代理服务启动中...'),
      ('debug', '加载配置文件: test.yaml'),
      ('info', '连接服务器: proxy.example.com:443'),
      ('warn', 'DNS查询延迟较高: 250ms'),
      ('info', '代理隧道建立成功'),
      ('debug', '流量统计: 上行 1.2MB, 下行 8.5MB'),
      ('error', '连接服务器超时: backup.example.com:443'),
      ('info', '代理服务运行稳定'),
    ];

    int index = 0;
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (index >= logs.length) {
        timer.cancel();
        return;
      }

      final (level, message) = logs[index];
      handleGoLog(level, message);
      index++;
    });
  }

  void dispose() {
    _logStream.dispose();
  }
}