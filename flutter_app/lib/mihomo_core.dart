// Mihomo核心桥接类
// 统一的Dart接口，支持MethodChannel(移动端)和FFI(桌面端)

import 'platform/desktop/ffi_bridge.dart';
import 'platform/mobile/method_channel.dart';

class MihomoCore {
  // 单例模式
  static final MihomoCore _instance = MihomoCore._internal();
  factory MihomoCore() => _instance;
  MihomoCore._internal();

  // 平台检测
  static bool get isDesktop =>
    (Uri.base.scheme == 'file') &&
    ['windows', 'macos', 'linux'].contains(_getPlatform());

  static bool get isMobile =>
    (Uri.base.scheme == 'file') &&
    ['android', 'ios'].contains(_getPlatform());

  static String _getPlatform() {
    // 简化版平台检测
    return const String.fromEnvironment('dart.platform', defaultValue: 'linux');
  }

  // 初始化核心
  Future<int> initializeCore(String configPath) async {
    print('🎉 初始化Mihomo核心... 配置路径: $configPath');

    if (isMobile) {
      return await _initializeMobile(configPath);
    } else if (isDesktop) {
      return await _initializeDesktop(configPath);
    }

    return -1; // 不支持的平台
  }

  // 移动端初始化 (MethodChannel)
  Future<int> _initializeMobile(String configPath) async {
    try {
      return await MihomoMethodChannel().initializeCore(configPath);
    } catch (e) {
      print('❌ 移动端MethodChannel初始化失败: $e');
      return -1;
    }
  }

  // 桌面端初始化 (FFI)
  Future<int> _initializeDesktop(String configPath) async {
    try {
      return MihomoFFI().initializeCore(configPath);
    } catch (e) {
      print('❌ 桌面端FFI初始化失败: $e');
      return -1;
    }
  }

  // 获取版本信息
  Future<String> getVersion() async {
    if (isMobile) {
      return await _getVersionMobile();
    } else if (isDesktop) {
      return await _getVersionDesktop();
    }

    return "Unknown";
  }

  Future<String> _getVersionMobile() async {
    try {
      return await MihomoMethodChannel().getVersion();
    } catch (e) {
      print('❌ 获取移动端版本失败: $e');
      return "Error: $e";
    }
  }

  Future<String> _getVersionDesktop() async {
    try {
      return MihomoFFI().getVersion();
    } catch (e) {
      print('❌ 获取桌面端版本失败: $e');
      return "Error: $e";
    }
  }

  // 启动代理
  Future<int> startProxy() async {
    print('🚀 启动Mihomo代理...');

    if (isMobile) {
      return await _startProxyMobile();
    } else if (isDesktop) {
      return await _startProxyDesktop();
    }

    return -1;
  }

  Future<int> _startProxyMobile() async {
    try {
      return await MihomoMethodChannel().startProxy();
    } catch (e) {
      print('❌ 移动端启动代理失败: $e');
      return -1;
    }
  }

  Future<int> _startProxyDesktop() async {
    try {
      return MihomoFFI().startProxy();
    } catch (e) {
      print('❌ 桌面端启动代理失败: $e');
      return -1;
    }
  }

  // 停止代理
  Future<int> stopProxy() async {
    print('🛑 停止Mihomo代理...');

    if (isMobile) {
      return await _stopProxyMobile();
    } else if (isDesktop) {
      return await _stopProxyDesktop();
    }

    return -1;
  }

  Future<int> _stopProxyMobile() async {
    try {
      return await MihomoMethodChannel().stopProxy();
    } catch (e) {
      print('❌ 移动端停止代理失败: $e');
      return -1;
    }
  }

  Future<int> _stopProxyDesktop() async {
    try {
      return MihomoFFI().stopProxy();
    } catch (e) {
      print('❌ 桌面端停止代理失败: $e');
      return -1;
    }
  }

  // 连接状态检查
  Future<bool> checkConnection() async {
    if (isMobile) {
      return await _checkConnectionMobile();
    } else if (isDesktop) {
      return await _checkConnectionDesktop();
    }
    return false;
  }

  Future<bool> _checkConnectionMobile() async {
    try {
      return await MihomoMethodChannel().checkConnection();
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkConnectionDesktop() async {
    try {
      return MihomoFFI().checkConnection();
    } catch (e) {
      return false;
    }
  }
}