// 移动端MethodChannel实现
// 支持Android和iOS

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MihomoMethodChannel {
  static const MethodChannel _channel = MethodChannel('mihomo_flutter_cross');

  // 初始化核心
  static Future<int> initializeCore(String configPath) async {
    try {
      final result = await _channel.invokeMethod<int>('initializeCore', {
        'configPath': configPath,
      });
      return result ?? -1;
    } catch (e) {
      debugPrint('❌ 初始化核心失败: $e');
      return -1;
    }
  }

  // 获取版本
  static Future<String> getVersion() async {
    try {
      final result = await _channel.invokeMethod<String>('getVersion');
      return result ?? 'Unknown';
    } catch (e) {
      debugPrint('❌ 获取版本失败: $e');
      return 'Error';
    }
  }

  // 启动代理
  static Future<int> startProxy() async {
    try {
      final result = await _channel.invokeMethod<int>('startProxy');
      return result ?? -1;
    } catch (e) {
      debugPrint('❌ 启动代理失败: $e');
      return -1;
    }
  }

  // 停止代理
  static Future<int> stopProxy() async {
    try {
      final result = await _channel.invokeMethod<int>('stopProxy');
      return result ?? -1;
    } catch (e) {
      debugPrint('❌ 停止代理失败: $e');
      return -1;
    }
  }

  // 检查MethodChannel连接状态
  static Future<bool> checkConnection() async {
    try {
      await _channel.invokeMethod('ping');
      return true;
    } catch (e) {
      debugPrint('❌ MethodChannel连接失败: $e');
      return false;
    }
  }
}