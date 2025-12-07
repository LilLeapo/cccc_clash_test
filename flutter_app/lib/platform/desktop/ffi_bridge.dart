// 桌面端FFI实现
// 支持Windows、macOS、Linux

import 'dart:ffi';
import 'dart:io' show Platform;

class MihomoFFI {
  static final MihomoFFI _instance = MihomoFFI._internal();
  factory MihomoFFI() => _instance;
  MihomoFFI._internal();

  late final DynamicLibrary _library;

  // FFI函数指针
  late final Pointer<NativeFunction<Int32 Function(Pointer<Utf8>)>> _initializeCore;
  late final Pointer<NativeFunction<Int32 Function()>> _startProxy;
  late final Pointer<NativeFunction<Int32 Function()>> _stopProxy;
  late final Pointer<NativeFunction<Pointer<Utf8> Function()>> _getVersion;

  bool _initialized = false;

  // 加载动态库
  bool _loadLibrary() {
    try {
      // 根据平台加载对应的动态库
      if (Platform.isWindows) {
        _library = DynamicLibrary.open('libs/desktop/mihomo_core_windows_amd64.dll');
      } else if (Platform.isMacOS) {
        _library = DynamicLibrary.open('libs/desktop/mihomo_core_darwin_amd64.dylib');
      } else if (Platform.isLinux) {
        _library = DynamicLibrary.open('libs/desktop/mihomo_core_linux_amd64.so');
      } else {
        print('❌ 不支持的桌面平台: ${Platform.operatingSystem}');
        return false;
      }

      // 解析函数指针
      _initializeCore = _library
          .lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>('InitializeCore');
      _startProxy = _library
          .lookup<NativeFunction<Int32 Function()>>('StartMihomoProxy');
      _stopProxy = _library
          .lookup<NativeFunction<Int32 Function()>>('StopMihomoProxy');
      _getVersion = _library
          .lookup<NativeFunction<Pointer<Utf8> Function()>>('GetMihomoVersion');

      _initialized = true;
      print('✅ FFI库加载成功');
      return true;
    } catch (e) {
      print('❌ FFI库加载失败: $e');
      return false;
    }
  }

  // 初始化核心
  int initializeCore(String configPath) {
    if (!_initialized && !_loadLibrary()) {
      return -1;
    }

    try {
      final pathPtr = configPath.toNativeUtf8();
      final result = _initializeCore.asFunction<int Function(Pointer<Utf8>)>()(pathPtr);
      pathPtr.dispose();
      return result;
    } catch (e) {
      print('❌ 初始化核心失败: $e');
      return -1;
    }
  }

  // 获取版本
  String getVersion() {
    if (!_initialized && !_loadLibrary()) {
      return 'Error: Library not loaded';
    }

    try {
      final versionPtr = _getVersion.asFunction<Pointer<Utf8> Function()>()();
      final version = versionPtr.toDartString();
      // 注意: 这里不应该dispose，因为Go端管理的内存
      return version;
    } catch (e) {
      print('❌ 获取版本失败: $e');
      return 'Error: $e';
    }
  }

  // 启动代理
  int startProxy() {
    if (!_initialized && !_loadLibrary()) {
      return -1;
    }

    try {
      return _startProxy.asFunction<int Function()>()();
    } catch (e) {
      print('❌ 启动代理失败: $e');
      return -1;
    }
  }

  // 停止代理
  int stopProxy() {
    if (!_initialized && !_loadLibrary()) {
      return -1;
    }

    try {
      return _stopProxy.asFunction<int Function()>()();
    } catch (e) {
      print('❌ 停止代理失败: $e');
      return -1;
    }
  }

  // 检查FFI连接状态
  bool checkConnection() {
    return _initialized || _loadLibrary();
  }

  // 清理资源
  void dispose() {
    // FFI库通常不需要显式清理
    // DynamicLibrary会在程序结束时自动释放
    _initialized = false;
  }
}