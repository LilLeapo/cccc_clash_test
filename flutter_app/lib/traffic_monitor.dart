// 流量监控与统计模块
// 实时监控网络流量、带宽使用和连接状态

import 'dart:async';
import 'dart:convert';

class TrafficStats {
  final DateTime timestamp;
  final int bytesUp;
  final int bytesDown;
  final int packetsUp;
  final int packetsDown;
  final int connectionsCount;

  TrafficStats({
    required this.timestamp,
    required this.bytesUp,
    required this.bytesDown,
    required this.packetsUp,
    required this.packetsDown,
    required this.connectionsCount,
  });

  factory TrafficStats.fromJson(Map<String, dynamic> json) {
    return TrafficStats(
      timestamp: DateTime.parse(json['timestamp']),
      bytesUp: json['bytesUp'] ?? 0,
      bytesDown: json['bytesDown'] ?? 0,
      packetsUp: json['packetsUp'] ?? 0,
      packetsDown: json['packetsDown'] ?? 0,
      connectionsCount: json['connectionsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'bytesUp': bytesUp,
      'bytesDown': bytesDown,
      'packetsUp': packetsUp,
      'packetsDown': packetsDown,
      'connectionsCount': connectionsCount,
    };
  }

  // 计算总流量
  int get totalBytes => bytesUp + bytesDown;

  // 计算总包数
  int get totalPackets => packetsUp + packetsDown;

  // 计算每秒上行带宽 (B/s)
  double get uploadSpeed => 0.0; // 需要在上层计算

  // 计算每秒下行带宽 (B/s)
  double get downloadSpeed => 0.0; // 需要在上层计算

  @override
  String toString() {
    return 'TrafficStats(up: ${formatBytes(bytesUp)}, down: ${formatBytes(bytesDown)}, total: ${formatBytes(totalBytes)})';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class TrafficMonitor {
  static final TrafficMonitor _instance = TrafficMonitor._internal();
  factory TrafficMonitor() => _instance;
  TrafficMonitor._internal();

  // 统计数据
  TrafficStats? _currentStats;
  final List<TrafficStats> _history = [];

  // Stream控制器
  final StreamController<TrafficStats> _statsController = StreamController<TrafficStats>.broadcast();
  final StreamController<double> _speedController = StreamController<double>.broadcast();

  // 定时器
  Timer? _updateTimer;
  static const Duration _updateInterval = Duration(seconds: 1);

  // 暴露的Stream
  Stream<TrafficStats> get statsStream => _statsController.stream;
  Stream<double> get speedStream => _speedController.stream;

  // 最近的速度数据
  double _lastUploadSpeed = 0.0;
  double _lastDownloadSpeed = 0.0;

  // 开始监控
  void startMonitoring() {
    if (_updateTimer != null) return;

    _updateTimer = Timer.periodic(_updateInterval, (timer) {
      _updateStats();
    });

    print('📊 流量监控已启动');
  }

  // 停止监控
  void stopMonitoring() {
    _updateTimer?.cancel();
    _updateTimer = null;

    print('📊 流量监控已停止');
  }

  // 记录数据包
  void recordPacket(bool isUpload, int size) {
    if (_currentStats == null) {
      _currentStats = TrafficStats(
        timestamp: DateTime.now(),
        bytesUp: 0,
        bytesDown: 0,
        packetsUp: 0,
        packetsDown: 0,
        connectionsCount: 0,
      );
    }

    if (isUpload) {
      _currentStats = TrafficStats(
        timestamp: DateTime.now(),
        bytesUp: _currentStats!.bytesUp + size,
        bytesDown: _currentStats!.bytesDown,
        packetsUp: _currentStats!.packetsUp + 1,
        packetsDown: _currentStats!.packetsDown,
        connectionsCount: _currentStats!.connectionsCount,
      );
    } else {
      _currentStats = TrafficStats(
        timestamp: DateTime.now(),
        bytesUp: _currentStats!.bytesUp,
        bytesDown: _currentStats!.bytesDown + size,
        packetsUp: _currentStats!.packetsUp,
        packetsDown: _currentStats!.packetsDown + 1,
        connectionsCount: _currentStats!.connectionsCount,
      );
    }
  }

  // 更新连接数
  void updateConnections(int count) {
    if (_currentStats == null) {
      _currentStats = TrafficStats(
        timestamp: DateTime.now(),
        bytesUp: 0,
        bytesDown: 0,
        packetsUp: 0,
        packetsDown: 0,
        connectionsCount: count,
      );
    } else {
      _currentStats = TrafficStats(
        timestamp: DateTime.now(),
        bytesUp: _currentStats!.bytesUp,
        bytesDown: _currentStats!.bytesDown,
        packetsUp: _currentStats!.packetsUp,
        packetsDown: _currentStats!.packetsDown,
        connectionsCount: count,
      );
    }
  }

  // 获取当前统计
  TrafficStats? get currentStats => _currentStats;

  // 获取历史数据
  List<TrafficStats> get history => List.from(_history);

  // 获取最近的N个数据点
  List<TrafficStats> getRecentStats([int count = 60]) {
    if (_history.length <= count) {
      return List.from(_history);
    }
    return _history.sublist(_history.length - count);
  }

  // 清除历史数据
  void clearHistory() {
    _history.clear();
    print('📊 流量历史数据已清除');
  }

  // 获取速度信息
  Map<String, double> getSpeedInfo() {
    return {
      'upload': _lastUploadSpeed,
      'download': _lastDownloadSpeed,
    };
  }

  // 模拟流量数据（用于测试）
  void simulateTraffic() {
    if (_updateTimer == null) {
      startMonitoring();
    }

    // 模拟随机流量
    Timer.periodic(Duration(seconds: 2), (timer) {
      final uploadSize = (100 + (2000 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).toInt();
      final downloadSize = (200 + (5000 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).toInt();

      recordPacket(true, uploadSize);
      recordPacket(false, downloadSize);

      final connections = 5 + (DateTime.now().millisecondsSinceEpoch % 20);
      updateConnections(connections);
    });
  }

  // 私有方法
  void _updateStats() {
    if (_currentStats == null) return;

    // 添加到历史记录
    _history.add(_currentStats!);

    // 保持最近1小时的数据
    final oneHourAgo = DateTime.now().subtract(Duration(hours: 1));
    _history.removeWhere((stats) => stats.timestamp.isBefore(oneHourAgo));

    // 计算速度
    _calculateSpeed();

    // 发送更新事件
    _statsController.add(_currentStats!);
  }

  void _calculateSpeed() {
    if (_history.length < 2) return;

    final current = _currentStats!;
    final previous = _history[_history.length - 2];

    final timeDiff = current.timestamp.difference(previous.timestamp).inMilliseconds / 1000.0;
    if (timeDiff <= 0) return;

    _lastDownloadSpeed = (current.bytesDown - previous.bytesDown) / timeDiff;
    _lastUploadSpeed = (current.bytesUp - previous.bytesUp) / timeDiff;

    // 发送速度更新
    final totalSpeed = _lastUploadSpeed + _lastDownloadSpeed;
    _speedController.add(totalSpeed);
  }

  // 格式化显示
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    if (bytesPerSecond < 1024 * 1024 * 1024) return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }

  // 生成流量报告
  Map<String, dynamic> generateReport() {
    final now = DateTime.now();
    final lastHour = now.subtract(Duration(hours: 1));

    final recentStats = _history.where((stats) => stats.timestamp.isAfter(lastHour)).toList();

    int totalUp = 0;
    int totalDown = 0;
    int totalPacketsUp = 0;
    int totalPacketsDown = 0;
    int peakConnections = 0;

    for (final stats in recentStats) {
      totalUp += stats.bytesUp;
      totalDown += stats.bytesDown;
      totalPacketsUp += stats.packetsUp;
      totalPacketsDown += stats.packetsDown;
      if (stats.connectionsCount > peakConnections) {
        peakConnections = stats.connectionsCount;
      }
    }

    return {
      'reportTime': now.toIso8601String(),
      'period': 'last_hour',
      'totalUpload': totalUp,
      'totalDownload': totalDown,
      'totalPacketsUp': totalPacketsUp,
      'totalPacketsDown': totalPacketsDown,
      'peakConnections': peakConnections,
      'averageSpeedUp': recentStats.isNotEmpty ? totalUp / recentStats.length : 0,
      'averageSpeedDown': recentStats.isNotEmpty ? totalDown / recentStats.length : 0,
    };
  }

  // 清理资源
  void dispose() {
    stopMonitoring();
    _statsController.close();
    _speedController.close();
    _history.clear();
  }
}