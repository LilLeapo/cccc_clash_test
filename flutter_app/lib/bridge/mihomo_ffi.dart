// Dart FFI 接口层
// 桌面端跨语言桥接实现

import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

// C类型定义
typedef Int32CFunction = Int32 Function();
typedef Int32CFunctionType = int Function();

typedef CharPtrCFunction = Pointer<Utf8> Function();
typedef CharPtrCFunctionType = Pointer<Utf8> Function();

typedef Int32CharPtrCFunction = Int32 Function(Pointer<Utf8>);
typedef Int32CharPtrCFunctionType = int Function(Pointer<Utf8>);

// Go桥接接口类
class MihomoBridge {
  static final MihomoBridge _instance = MihomoBridge._internal();
  factory MihomoBridge() => _instance;
  MihomoBridge._internal();

  late final DynamicLibrary _library;

  // 函数指针声明
  late final Int32CharPtrCFunctionType _initializeCore;
  late final Int32CFunctionType _startMihomoProxy;
  late final Int32CFunctionType _stopMihomoProxy;
  late final Int32CharPtrCFunctionType _reloadConfig;
  late final CharPtrCFunctionType _getMihomoStatus;
  late final CharPtrCFunctionType _getMihomoVersion;
  late final Int32CharPtrCFunctionType _logCallback;
  late final Int32CharPtrCFunctionType _setLogLevel;
  late final CharPtrCFunctionType _helloWorld;
  late final Int32CharPtrCFunctionType _tunCreate;
  late final Int32CFunctionType _tunStart;
  late final Int32CFunctionType _tunStop;
  late final CharPtrCFunctionType _tunReadPacket;
  late final Int32CharPtrCFunctionType _tunWritePacket;
  late final CharPtrCFunctionType _getTrafficStats;
  late final Int32CFunctionType _resetTrafficStats;

  // 内存管理函数
  late final Pointer<Void> Function(Pointer<Utf8>) _freeString;
  late final Int32CFunctionType _getStringLength;
  late final CharPtrCFunctionType _getLastError;
  late final VoidCFunctionType _clearError;

  // 状态管理
  bool _initialized = false;
  bool _running = false;

  // 初始化库
  bool initialize() {
    if (_initialized) return true;

    try {
      // 加载动态库
      _library = _loadLibrary();

      // 解析函数指针
      _resolveFunctions();

      _initialized = true;
      print('✅ Mihomo Bridge FFI 初始化成功 (${Platform.operatingSystem})');
      return true;
    } catch (e) {
      print('❌ Mihomo Bridge FFI 初始化失败: $e');
      return false;
    }
  }

  // 加载动态库
  DynamicLibrary _loadLibrary() {
    String libraryName;
    String? libraryPath;

    if (Platform.isWindows) {
      libraryName = 'mihomo_bridge.dll';
    } else if (Platform.isMacOS) {
      libraryName = 'libmihomo_bridge.dylib';
    } else {
      libraryName = 'libmihomo_bridge.so';
    }

    // 优先从 libs/desktop 目录加载
    libraryPath = 'libs/desktop/$libraryName';
    if (File(libraryPath).existsSync()) {
      return DynamicLibrary.open(libraryPath);
    }

    // 尝试当前目录
    try {
      return DynamicLibrary.open(libraryName);
    } catch (e) {
      // 最后尝试系统路径
      if (Platform.isMacOS) {
        return DynamicLibrary.open('/usr/local/lib/$libraryName');
      } else if (Platform.isLinux) {
        return DynamicLibrary.open('/usr/lib/$libraryName');
      }
      rethrow;
    }
  }

  // 解析函数指针
  void _resolveFunctions() {
    _initializeCore = _library
        .lookup<NativeFunction<Int32CharPtrCFunction>>('InitializeCore')
        .asFunction();

    _startMihomoProxy = _library
        .lookup<NativeFunction<Int32CFunction>>('StartMihomoProxy')
        .asFunction();

    _stopMihomoProxy = _library
        .lookup<NativeFunction<Int32CFunction>>('StopMihomoProxy')
        .asFunction();

    _reloadConfig = _library
        .lookup<NativeFunction<Int32CharPtrCFunction>>('ReloadConfig')
        .asFunction();

    _getMihomoStatus = _library
        .lookup<NativeFunction<CharPtrCFunction>>('GetMihomoStatus')
        .asFunction();

    _getMihomoVersion = _library
        .lookup<NativeFunction<CharPtrCFunction>>('GetMihomoVersion')
        .asFunction();

    _logCallback = _library
        .lookup<NativeFunction<Int32CharPtrCFunction>>('LogCallback')
        .asFunction();

    _setLogLevel = _library
        .lookup<NativeFunction<Int32CharPtrCFunction>>('SetLogLevel')
        .asFunction();

    _helloWorld = _library
        .lookup<NativeFunction<CharPtrCFunction>>('HelloWorld')
        .asFunction();

    _tunCreate = _library
        .lookup<NativeFunction<Int32CharPtrCFunction>>('TunCreate')
        .asFunction();

    _tunStart = _library
        .lookup<NativeFunction<Int32CFunction>>('TunStart')
        .asFunction();

    _tunStop = _library
        .lookup<NativeFunction<Int32CFunction>>('TunStop')
        .asFunction();

    _tunReadPacket = _library
        .lookup<NativeFunction<CharPtrCFunction>>('TunReadPacket')
        .asFunction();

    _tunWritePacket = _library
        .lookup<NativeFunction<Int32CharPtrCFunction>>('TunWritePacket')
        .asFunction();

    _getTrafficStats = _library
        .lookup<NativeFunction<CharPtrCFunction>>('GetTrafficStats')
        .asFunction();

    _resetTrafficStats = _library
        .lookup<NativeFunction<Int32CFunction>>('ResetTrafficStats')
        .asFunction();

    // 内存管理函数
    _freeString = _library
        .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('FreeString')
        .asFunction();

    _getStringLength = _library
        .lookup<NativeFunction<Int32CFunction>>('GetStringLength')
        .asFunction();

    _getLastError = _library
        .lookup<NativeFunction<CharPtrCFunction>>('GetLastError')
        .asFunction();

    _clearError = _library
        .lookup<NativeFunction<Void Function()>>('ClearError')
        .asFunction();
  }

  // 核心生命周期方法
  int initializeCore(String configPath) {
    if (!_initialized) {
      if (!initialize()) return -1;
    }

    final pathPtr = configPath.toNativeUtf8();
    try {
      final result = _initializeCore(pathPtr);
      return result;
    } finally {
      pathPtr.dispose();
    }
  }

  int startMihomoProxy() {
    if (!_initialized) return -1;

    final result = _startMihomoProxy();
    if (result == 0) {
      _running = true;
    }
    return result;
  }

  int stopMihomoProxy() {
    if (!_initialized) return -1;

    final result = _stopMihomoProxy();
    if (result == 0) {
      _running = false;
    }
    return result;
  }

  int reloadConfig(String configPath) {
    if (!_initialized) return -1;

    final pathPtr = configPath.toNativeUtf8();
    try {
      return _reloadConfig(pathPtr);
    } finally {
      pathPtr.dispose();
    }
  }

  // 查询方法
  String getMihomoStatus() {
    if (!_initialized) return '{"status": "error", "error": "not initialized"}';

    try {
      final statusPtr = _getMihomoStatus();
      final status = statusPtr.toDartString();
      // 注意：不要释放这个指针，因为它是Go端管理的内存
      return status;
    } catch (e) {
      return '{"status": "error", "error": "$e"}';
    }
  }

  String getMihomoVersion() {
    if (!_initialized) return "error: not initialized";

    try {
      final versionPtr = _getMihomoVersion();
      final version = versionPtr.toDartString();
      // 不要释放这个指针
      return version;
    } catch (e) {
      return "error: $e";
    }
  }

  String helloWorld() {
    if (!_initialized) return "error: not initialized";

    try {
      final helloPtr = _helloWorld();
      final hello = helloPtr.toDartString();
      // 不要释放这个指针
      return hello;
    } catch (e) {
      return "error: $e";
    }
  }

  // TUN相关方法
  int tunCreate(String tunName) {
    if (!_initialized) return -1;

    final namePtr = tunName.toNativeUtf8();
    try {
      return _tunCreate(namePtr);
    } finally {
      namePtr.dispose();
    }
  }

  int tunStart() {
    if (!_initialized) return -1;
    return _tunStart();
  }

  int tunStop() {
    if (!_initialized) return -1;
    return _tunStop();
  }

  String tunReadPacket() {
    if (!_initialized) return '{"error": "not initialized"}';

    try {
      final packetPtr = _tunReadPacket();
      final packet = packetPtr.toDartString();
      // 不要释放这个指针
      return packet;
    } catch (e) {
      return '{"error": "$e"}';
    }
  }

  int tunWritePacket(String packetData) {
    if (!_initialized) return -1;

    final dataPtr = packetData.toNativeUtf8();
    try {
      return _tunWritePacket(dataPtr);
    } finally {
      dataPtr.dispose();
    }
  }

  // 流量统计
  String getTrafficStats() {
    if (!_initialized) return '{"error": "not initialized"}';

    try {
      final statsPtr = _getTrafficStats();
      final stats = statsPtr.toDartString();
      // 不要释放这个指针
      return stats;
    } catch (e) {
      return '{"error": "$e"}';
    }
  }

  int resetTrafficStats() {
    if (!_initialized) return -1;
    return _resetTrafficStats();
  }

  // 状态查询
  bool get isInitialized => _initialized;
  bool get isRunning => _running;

  // 清理资源
  void dispose() {
    if (_running) {
      stopMihomoProxy();
    }
    // FFI库通常不需要显式清理
    _initialized = false;
    _running = false;
  }
}