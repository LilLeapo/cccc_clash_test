// 主应用程序入口
// 简单的测试界面来验证桥接功能

import 'package:flutter/material.dart';
import 'mihomo_core.dart';
import 'platform/mobile/method_channel.dart';
import 'platform/desktop/ffi_bridge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mihomo Flutter Cross',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MihomoHomePage(),
    );
  }
}

class MihomoHomePage extends StatefulWidget {
  const MihomoHomePage({super.key});

  @override
  State<MihomoHomePage> createState() => _MihomoHomePageState();
}

class _MihomoHomePageState extends State<MihomoHomePage> {
  final MihomoCore _mihomoCore = MihomoCore();

  String _status = '准备就绪';
  String _version = 'Unknown';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializePlatform();
  }

  Future<void> _initializePlatform() async {
    setState(() {
      _status = '初始化中...';
    });

    // 初始化核心
    final result = await _mihomoCore.initializeCore('test.yaml');

    if (result == 0) {
      setState(() {
        _status = '✅ 初始化成功';
        _isConnected = true;
      });

      // 获取版本
      _version = await _mihomoCore.getVersion();
      setState(() {
        _version = _version;
      });
    } else {
      setState(() {
        _status = '❌ 初始化失败 (代码: $result)';
      });
    }
  }

  Future<void> _startProxy() async {
    if (!_isConnected) {
      _showMessage('请先初始化核心');
      return;
    }

    setState(() {
      _status = '启动中...';
    });

    final result = await _mihomoCore.startProxy();

    if (result == 0) {
      setState(() {
        _status = '✅ 代理运行中';
      });
    } else {
      setState(() {
        _status = '❌ 启动失败 (代码: $result)';
      });
    }
  }

  Future<void> _stopProxy() async {
    setState(() {
      _status = '停止中...';
    });

    final result = await _mihomoCore.stopProxy();

    if (result == 0) {
      setState(() {
        _status = '✅ 已停止';
      });
    } else {
      setState(() {
        _status = '❌ 停止失败 (代码: $result)';
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mihomo Flutter Cross'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 状态显示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '状态',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status,
                        style: TextStyle(
                          fontSize: 16,
                          color: _status.startsWith('✅')
                              ? Colors.green
                              : _status.startsWith('❌')
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 版本信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '版本信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _version,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 操作按钮
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _startProxy,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('启动代理'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _stopProxy,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止代理'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _initializePlatform,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新初始化'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 平台信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '平台信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '桌面端: ${MihomoCore.isDesktop}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '移动端: ${MihomoCore.isMobile}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}