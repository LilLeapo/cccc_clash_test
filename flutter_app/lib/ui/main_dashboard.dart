// main_dashboard.dart - 主仪表板界面
// Material 3 设计实现，集成TUN功能和配置管理

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../bridge/mihomo_ffi.dart';
import '../bridge/config_manager.dart';
import 'config_panel.dart';

/// 主仪表板页面
class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({Key? key}) : super(key: key);

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage>
    with TickerProviderStateMixin {
  // 状态管理
  bool _isProxyRunning = false;
  bool _isTunActive = false;
  String _currentConfig = '未配置';
  String _proxyMode = 'Rule';
  int _connectedClients = 0;

  // 统计数据
  int _totalTraffic = 0;
  int _uploadTraffic = 0;
  int _downloadTraffic = 0;
  double _cpuUsage = 0.0;
  double _memoryUsage = 0.0;

  // 图表数据
  List<FlSpot> _uploadChartData = [];
  List<FlSpot> _downloadChartData = [];
  Timer? _statsUpdateTimer;

  // 动画控制器
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStatsCollection();
  }

  @override
  void dispose() {
    _statsUpdateTimer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // =============================================================================
  // 初始化和动画
  // =============================================================================

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  void _startStatsCollection() {
    _statsUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateStatistics();
    });
  }

  void _updateStatistics() {
    setState(() {
      // 模拟统计数据更新
      _totalTraffic += 1024; // 每次增加1KB
      _uploadTraffic += 256; // 上传256B
      _downloadTraffic += 768; // 下载768B

      // 更新图表数据
      final timestamp = DateTime.now().millisecondsSinceEpoch / 1000;
      final uploadSpot = FlSpot(timestamp, _uploadTraffic.toDouble() / 1024);
      final downloadSpot = FlSpot(timestamp, _downloadTraffic.toDouble() / 1024);

      _uploadChartData.add(uploadSpot);
      _downloadChartData.add(downloadSpot);

      // 保持最新50个数据点
      if (_uploadChartData.length > 50) {
        _uploadChartData.removeAt(0);
      }
      if (_downloadChartData.length > 50) {
        _downloadChartData.removeAt(0);
      }

      // 模拟CPU和内存使用
      _cpuUsage = math.Random().nextDouble() * 100;
      _memoryUsage = math.Random().nextDouble() * 100;
    });
  }

  // =============================================================================
  // 功能操作
  // =============================================================================

  Future<void> _startProxy() async {
    try {
      final result = await MihomoFFI.instance.startProxy();
      if (result) {
        setState(() {
          _isProxyRunning = true;
        });
        _showSuccessSnackBar('代理服务启动成功');
      } else {
        _showErrorSnackBar('代理服务启动失败');
      }
    } catch (e) {
      _showErrorSnackBar('启动异常: $e');
    }
  }

  Future<void> _stopProxy() async {
    try {
      final result = await MihomoFFI.instance.stopProxy();
      if (result) {
        setState(() {
          _isProxyRunning = false;
        });
        _showSuccessSnackBar('代理服务已停止');
      } else {
        _showErrorSnackBar('停止服务失败');
      }
    } catch (e) {
      _showErrorSnackBar('停止异常: $e');
    }
  }

  Future<void> _toggleTunMode() async {
    try {
      if (_isTunActive) {
        final result = await MihomoFFI.instance.stopTun();
        if (result) {
          setState(() {
            _isTunActive = false;
          });
          _showSuccessSnackBar('TUN模式已关闭');
        }
      } else {
        final result = await MihomoFFI.instance.startTun();
        if (result) {
          setState(() {
            _isTunActive = true;
          });
          _showSuccessSnackBar('TUN模式已开启');
        }
      }
    } catch (e) {
      _showErrorSnackBar('TUN操作异常: $e');
    }
  }

  // =============================================================================
  // UI 构建
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildTrafficChart(),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 16),
                  _buildConfigInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Mihomo Flutter Cross',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Icon(
                    Icons.radio,
                    size: 80,
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showSettingsMenu(),
          tooltip: '设置',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshData(),
          tooltip: '刷新',
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isProxyRunning ? '代理服务运行中' : '代理服务已停止',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '当前模式: $_proxyMode  |  配置文件: $_currentConfig',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildModeBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _isProxyRunning
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isProxyRunning
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline).withOpacity(0.3),
                blurRadius: 10 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isTunActive
            ? Theme.of(context).colorScheme.tertiaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isTunActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 16,
            color: _isTunActive
                ? Theme.of(context).colorScheme.onTertiaryContainer
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            _isTunActive ? 'TUN模式' : '常规模式',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _isTunActive
                  ? Theme.of(context).colorScheme.onTertiaryContainer
                  : Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速操作',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: _isProxyRunning ? Icons.stop : Icons.play_arrow,
                title: _isProxyRunning ? '停止代理' : '启动代理',
                color: _isProxyRunning ? Colors.red : Colors.green,
                onTap: _isProxyRunning ? _stopProxy : _startProxy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.vpn_key,
                title: _isTunActive ? '关闭TUN' : '开启TUN',
                color: _isTunActive ? Colors.orange : Colors.blue,
                onTap: _toggleTunMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '流量统计',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 10,
                    verticalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 10,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Theme.of(context).colorScheme.surface,
                      getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineTouchedSpot spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} KB/s',
                            Theme.of(context).textTheme.bodyMedium!,
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _uploadChartData,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: _downloadChartData,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.secondary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildChartLegend(
                  color: Theme.of(context).colorScheme.primary,
                  label: '上传',
                ),
                const SizedBox(width: 20),
                _buildChartLegend(
                  color: Theme.of(context).colorScheme.secondary,
                  label: '下载',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.data_usage,
          title: '总流量',
          value: '${(_totalTraffic / 1024).toStringAsFixed(1)} KB',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.upload,
          title: '上传流量',
          value: '${(_uploadTraffic / 1024).toStringAsFixed(1)} KB',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.download,
          title: '下载流量',
          value: '${(_downloadTraffic / 1024).toStringAsFixed(1)} KB',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.people,
          title: '连接客户端',
          value: _connectedClients.toString(),
          color: Colors.purple,
        ),
        _buildStatCard(
          icon: Icons.memory,
          title: 'CPU使用率',
          value: '${_cpuUsage.toStringAsFixed(1)}%',
          color: Colors.red,
        ),
        _buildStatCard(
          icon: Icons.storage,
          title: '内存使用',
          value: '${_memoryUsage.toStringAsFixed(1)}%',
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.config,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          '配置管理',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '当前配置: $_currentConfig',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToConfigPanel(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showQuickActions,
      icon: const Icon(Icons.add),
      label: const Text('快速操作'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  // =============================================================================
  // 导航和菜单
  // =============================================================================

  void _navigateToConfigPanel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConfigPanelPage(),
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.config),
              title: const Text('配置管理'),
              subtitle: const Text('管理代理配置'),
              onTap: () {
                Navigator.pop(context);
                _navigateToConfigPanel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('关于应用'),
              subtitle: const Text('版本和作者信息'),
              onTap: () => _showAboutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _isProxyRunning ? _stopProxy() : _startProxy();
                    },
                    icon: Icon(_isProxyRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(_isProxyRunning ? '停止代理' : '启动代理'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProxyRunning ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleTunMode();
                    },
                    icon: Icon(_isTunActive ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    label: Text(_isTunActive ? '关闭TUN' : '开启TUN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTunActive ? Colors.orange : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Mihomo Flutter Cross',
      applicationVersion: 'v0.1.0-alpha',
      applicationIcon: const Icon(Icons.radio, size: 48),
      children: [
        const Text('基于Clash Meta内核的跨平台代理客户端'),
        const SizedBox(height: 8),
        const Text('支持Android、iOS和桌面端的统一体验'),
        const SizedBox(height: 8),
        Text('作者: MiniMax-M2'),
      ],
    );
  }

  void _refreshData() {
    _showSuccessSnackBar('数据已刷新');
    _updateStatistics();
  }

  // =============================================================================
  // 消息提示
  // =============================================================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}