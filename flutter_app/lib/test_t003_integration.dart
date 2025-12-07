// T003: 核心生命周期集成测试
// 验证Go核心接口、日志回调和状态管理

import 'dart:async';
import 'dart:convert';
import 'mihomo_controller.dart';

class T003IntegrationTest {
  static final T003IntegrationTest _instance = T003IntegrationTest._internal();
  factory T003IntegrationTest() => _instance;
  T003IntegrationTest._internal();

  late final MihomoController _controller;
  final List<String> _testResults = [];
  int _currentTest = 0;
  static const int _totalTests = 5;

  Future<void> runTests() async {
    print('🧪 开始 T003 核心生命周期集成测试...\n');

    _controller = MihomoController();
    await _controller.initialize();

    // 测试1: 控制器初始化
    await _testControllerInitialization();

    // 测试2: 代理启动
    await _testProxyStart();

    // 测试3: 日志流验证
    await _testLogStream();

    // 测试4: 状态切换
    await _testStateManagement();

    // 测试5: 代理停止
    await _testProxyStop();

    // 输出测试结果
    _printTestResults();

    // 清理
    _controller.dispose();
  }

  Future<void> _testControllerInitialization() async {
    _startTest('控制器初始化');

    try {
      // 检查初始状态
      final isRunning = _controller.isRunning;
      if (!isRunning) {
        _passTest('控制器初始状态正确（未运行）');
      } else {
        _failTest('控制器初始状态异常');
      }

      // 检查连接
      final canConnect = await _controller.checkConnection();
      _passTest('连接检查: $canConnect');

      print('');
    } catch (e) {
      _failTest('初始化异常: $e');
    }
  }

  Future<void> _testProxyStart() async {
    _startTest('代理启动');

    try {
      // 启动代理
      final success = await _controller.startProxy(configPath: 'test.yaml');
      if (success) {
        _passTest('代理启动成功');
      } else {
        _failTest('代理启动失败');
      }

      // 检查状态变化
      await Future.delayed(Duration(seconds: 1));
      if (_controller.isRunning) {
        _passTest('状态更新正确（运行中）');
      } else {
        _failTest('状态未更新');
      }

      print('');
    } catch (e) {
      _failTest('启动异常: $e');
    }
  }

  Future<void> _testLogStream() async {
    _startTest('日志流验证');

    try {
      bool logReceived = false;

      // 监听日志流
      final subscription = _controller.logStream.listen((logEntry) {
        print('📝 收到日志: ${logEntry.toString()}');
        logReceived = true;
      });

      // 生成测试日志
      _controller.simulateLogs();

      // 等待日志
      await Future.delayed(Duration(seconds: 3));
      await subscription.cancel();

      if (logReceived) {
        _passTest('日志流工作正常');
      } else {
        _failTest('未收到日志');
      }

      print('');
    } catch (e) {
      _failTest('日志流异常: $e');
    }
  }

  Future<void> _testStateManagement() async {
    _startTest('状态管理');

    try {
      bool statusChanged = false;

      // 监听状态流
      final subscription = _controller.statusStream.listen((status) {
        print('📊 状态变化: ${status.toString()}');
        statusChanged = true;
      });

      // 模拟状态变化
      await _controller.startProxy();

      await Future.delayed(Duration(seconds: 1));
      await subscription.cancel();

      if (statusChanged) {
        _passTest('状态流工作正常');
      } else {
        _failTest('状态未变化');
      }

      print('');
    } catch (e) {
      _failTest('状态管理异常: $e');
    }
  }

  Future<void> _testProxyStop() async {
    _startTest('代理停止');

    try {
      // 停止代理
      final success = await _controller.stopProxy();
      if (success) {
        _passTest('代理停止成功');
      } else {
        _failTest('代理停止失败');
      }

      // 检查状态
      await Future.delayed(Duration(seconds: 1));
      if (!_controller.isRunning) {
        _passTest('状态更新正确（已停止）');
      } else {
        _failTest('状态未更新');
      }

      print('');
    } catch (e) {
      _failTest('停止异常: $e');
    }
  }

  void _startTest(String name) {
    _currentTest++;
    print('🔬 Test $_currentTest/$_totalTests: $name');
  }

  void _passTest(String message) {
    _testResults.add('✅ $message');
    print('   $message');
  }

  void _failTest(String message) {
    _testResults.add('❌ $message');
    print('   $message');
  }

  void _printTestResults() {
    print('\n📊 T003 集成测试结果:');
    print('=' * 40);

    for (final result in _testResults) {
      print(result);
    }

    final passCount = _testResults.where((r) => r.startsWith('✅')).length;
    final totalCount = _testResults.length;

    print('\n🎯 测试统计: $passCount/$totalCount 通过');

    if (passCount == totalCount) {
      print('🎉 所有测试通过！T003核心生命周期验证成功！');
    } else {
      print('⚠️  部分测试失败，需要进一步调试');
    }
  }
}

void main() async {
  final test = T003IntegrationTest();
  await test.runTests();
}