// T002: 完整的Dart->Bridge->Go链路集成测试
// 测试FFI调用和动态库加载

import 'dart:ffi';
import 'dart:io' show Platform;

void main() {
  print('🧪 开始Dart->Go链路测试...');

  // 测试FFI桥接
  final bridge = MihomoFFIBridge();

  // 测试初始化
  print('📦 测试初始化...');
  final initResult = bridge.initializeCore('test.yaml');
  print('初始化结果: $initResult');

  // 测试获取版本
  print('📦 测试获取版本...');
  final version = bridge.getMihomoVersion();
  print('版本信息: $version');

  // 测试Hello World
  print('📦 测试Hello World...');
  final hello = bridge.helloWorld();
  print('Hello: $hello');

  print('✅ 测试完成!');
}

class MihomoFFIBridge {
  late final DynamicLibrary _library;
  late final Pointer<NativeFunction<Pointer<Utf8> Function()>> _helloWorld;
  late final Pointer<NativeFunction<Int32 Function(Pointer<Utf8>)>> _initializeCore;
  late final Pointer<NativeFunction<Pointer<Utf8> Function()>> _getVersion;

  bool _loaded = false;

  // 加载动态库
  bool _loadLibrary() {
    try {
      // 在Linux上测试，使用.so文件
      if (Platform.isLinux) {
        final libPath = 'libs/desktop/mihomo_core_linux_amd64.so';
        print('📁 加载库: $libPath');
        _library = DynamicLibrary.open(libPath);
      } else {
        print('❌ 当前平台不支持: ${Platform.operatingSystem}');
        return false;
      }

      // 解析函数指针
      _helloWorld = _library.lookup<NativeFunction<Pointer<Utf8> Function()>>('HelloWorld');
      _initializeCore = _library.lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>('InitializeCore');
      _getVersion = _library.lookup<NativeFunction<Pointer<Utf8> Function()>>('GetMihomoVersion');

      _loaded = true;
      print('✅ 动态库加载成功');
      return true;
    } catch (e) {
      print('❌ 动态库加载失败: $e');
      return false;
    }
  }

  // Hello World
  String helloWorld() {
    if (!_loaded && !_loadLibrary()) {
      return 'Error: Library not loaded';
    }

    try {
      final helloPtr = _helloWorld.asFunction<Pointer<Utf8> Function()>()();
      final hello = helloPtr.toDartString();
      // 注意: Go管理的内存不应该dispose
      return hello;
    } catch (e) {
      print('❌ Hello World调用失败: $e');
      return 'Error: $e';
    }
  }

  // 初始化核心
  int initializeCore(String configPath) {
    if (!_loaded && !_loadLibrary()) {
      return -1;
    }

    try {
      final pathPtr = configPath.toNativeUtf8();
      final result = _initializeCore.asFunction<int Function(Pointer<Utf8>)>()(pathPtr);
      pathPtr.dispose();
      return result;
    } catch (e) {
      print('❌ 初始化调用失败: $e');
      return -1;
    }
  }

  // 获取版本
  String getVersion() {
    if (!_loaded && !_loadLibrary()) {
      return 'Error: Library not loaded';
    }

    try {
      final versionPtr = _getVersion.asFunction<Pointer<Utf8> Function()>()();
      final version = versionPtr.toDartString();
      return version;
    } catch (e) {
      print('❌ 获取版本调用失败: $e');
      return 'Error: $e';
    }
  }
}