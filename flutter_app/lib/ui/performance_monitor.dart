// performance_monitor.dart - 性能监控界面
// 流量可视化和系统性能监控

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../bridge/mihomo_ffi.dart';

/// 性能监控页面
class PerformanceMonitorPage extends StatefulWidget {
  const PerformanceMonitorPage({Key? key}) : super(key: key);

  @override
  State<PerformanceMonitorPage> createState() => _PerformanceMonitorPageState();
}

class _PerformanceMonitorPageState extends State<PerformanceMonitorPage>
    with TickerProviderStateMixin {
  // 性能数据
  double _cpuUsage = 0.0;
  double _memoryUsage = 0.0;
  double _networkUsage = 0.0;
  int _connectedDevices = 0;
  int _totalConnections = 0;

  // 历史数据
  List<FlSpot> _cpuHistory = [];
  List<FlSpot> _memoryHistory = [];
  List<FlSpot> _networkHistory = [];
  List<FlSpot> _connectionHistory = [];

  // 图表配置
  Timer? _updateTimer;
  int _dataPointCount = 0;

  // 动画控制器
  late AnimationController _cpuController;
  late AnimationController _memoryController;
  late Animation<double> _cpuAnimation;
  late Animation<double> _memoryAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startDataCollection();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _cpuController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  // =============================================================================
  // 初始化和动画
  // =============================================================================

  void _initializeAnimations() {
    _cpuController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _memoryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cpuAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cpuController,
      curve: Curves.elasticOut,
    ));

    _memoryAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _memoryController,
      curve: Curves.bounceOut,
    ));
  }

  void _startDataCollection() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updatePerformanceData();
    });
  }

  void _updatePerformanceData() {
    // 模拟真实性能数据获取
    setState(() {
      // CPU使用率 (0-100%)
      _cpuUsage = 20 + (math.Random().nextDouble() * 60);

      // 内存使用率 (0-100%)
      _memoryUsage = 30 + (math.Random().nextDouble() * 50);

      // 网络使用率 (0-100%)
      _networkUsage = 10 + (math.Random().nextDouble() * 70);

      // 连接设备数
      _connectedDevices = math.Random().nextInt(5);

      // 总连接数
      _totalConnections = math.Random().nextInt(20) + 5;

      // 更新时间戳
      final timestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;

      // 更新历史数据
      _cpuHistory.add(FlSpot(timestamp, _cpuUsage));
      _memoryHistory.add(FlSpot(timestamp, _memoryUsage));
      _networkHistory.add(FlSpot(timestamp, _networkUsage));
      _connectionHistory.add(FlSpot(timestamp, _totalConnections.toDouble()));

      // 保持最新50个数据点
      _keepDataPoints();

      // 触发动画
      _cpuController.forward().then((_) => _cpuController.reverse());
      _memoryController.forward().then((_) => _memoryController.reverse());

      _dataPointCount++;
    });
  }

  void _keepDataPoints() {
    const maxPoints = 50;

    if (_cpuHistory.length > maxPoints) {
      _cpuHistory.removeAt(0);
    }
    if (_memoryHistory.length > maxPoints) {
      _memoryHistory.removeAt(0);
    }
    if (_networkHistory.length > maxPoints) {
      _networkHistory.removeAt(0);
    }
    if (_connectionHistory.length > maxPoints) {
      _connectionHistory.removeAt(0);
    }
  }

  // =============================================================================
  // UI构建
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
                  _buildOverviewCards(),
                  const SizedBox(height: 16),
                  _buildPerformanceCharts(),
                  const SizedBox(height: 16),
                  _buildConnectionStats(),
                  const SizedBox(height: 16),
                  _buildSystemInfo(),
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
          '性能监控',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.analytics,
              size: 80,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _resetData,
          tooltip: '重置数据',
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '实时概览',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              icon: Icons.memory,
              title: 'CPU使用率',
              value: '${_cpuUsage.toStringAsFixed(1)}%',
              color: _getUsageColor(_cpuUsage),
              progress: _cpuUsage / 100,
              animation: _cpuAnimation,
            ),
            _buildMetricCard(
              icon: Icons.storage,
              title: '内存使用',
              value: '${_memoryUsage.toStringAsFixed(1)}%',
              color: _getUsageColor(_memoryUsage),
              progress: _memoryUsage / 100,
              animation: _memoryAnimation,
            ),
            _buildMetricCard(
              icon: Icons.network_check,
              title: '网络使用',
              value: '${_networkUsage.toStringAsFixed(1)}%',
              color: _getUsageColor(_networkUsage),
              progress: _networkUsage / 100,
              animation: _cpuAnimation,
            ),
            _buildMetricCard(
              icon: Icons.people,
              title: '连接设备',
              value: _connectedDevices.toString(),
              color: Colors.purple,
              progress: _connectedDevices / 10.0,
              animation: _memoryAnimation,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required double progress,
    required Animation<double> animation,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (0.4 * animation.value),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性能趋势',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildCpuChart(),
        const SizedBox(height: 16),
        _buildNetworkChart(),
      ],
    );
  }

  Widget _buildCpuChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'CPU & 内存使用趋势',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
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
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                        interval: 20,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  minX: _cpuHistory.isNotEmpty ? _cpuHistory.first.x : 0,
                  maxX: _cpuHistory.isNotEmpty ? _cpuHistory.last.x : 60,
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Theme.of(context).colorScheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineTouchedSpot spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}%',
                            Theme.of(context).textTheme.bodyMedium!,
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _cpuHistory,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: _memoryHistory,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.secondary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
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
                  label: 'CPU',
                ),
                const SizedBox(width: 20),
                _buildChartLegend(
                  color: Theme.of(context).colorScheme.secondary,
                  label: '内存',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.network_check, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  '网络使用 & 连接统计',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: 10,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                        interval: 20,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  minX: _networkHistory.isNotEmpty ? _networkHistory.first.x : 0,
                  maxX: _networkHistory.isNotEmpty ? _networkHistory.last.x : 60,
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Theme.of(context).colorScheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineTouchedSpot spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}',
                            Theme.of(context).textTheme.bodyMedium!,
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _networkHistory,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.tertiary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(
              color: Theme.of(context).colorScheme.tertiary,
              label: '网络使用率',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  '连接统计',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: '当前连接',
                    value: _connectedDevices.toString(),
                    icon: Icons.device_hub,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    label: '总连接数',
                    value: _totalConnections.toString(),
                    icon: Icons.link,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: _connectedDevices.toDouble(),
                      color: Colors.blue,
                      title: '${_connectedDevices}',
                      radius: 30,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: (_totalConnections - _connectedDevices).toDouble(),
                      color: Colors.grey.shade300,
                      title: '${_totalConnections - _connectedDevices}',
                      radius: 30,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 20,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '系统信息',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('应用版本', 'v0.1.0-alpha'),
            _buildInfoRow('数据更新', '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
            _buildInfoRow('监控时间', '${_dataPointCount * 2}秒'),
            _buildInfoRow('状态', _getSystemStatus()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _toggleMonitoring,
      icon: Icon(_updateTimer?.isActive == true ? Icons.pause : Icons.play_arrow),
      label: Text(_updateTimer?.isActive == true ? '暂停监控' : '开始监控'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  // =============================================================================
  // 辅助方法
  // =============================================================================

  Widget _buildChartLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

  Color _getUsageColor(double usage) {
    if (usage < 50) return Colors.green;
    if (usage < 80) return Colors.orange;
    return Colors.red;
  }

  String _getSystemStatus() {
    final avgUsage = (_cpuUsage + _memoryUsage) / 2;
    if (avgUsage < 30) return '良好';
    if (avgUsage < 70) return '正常';
    return '高负载';
  }

  void _toggleMonitoring() {
    if (_updateTimer?.isActive == true) {
      _updateTimer?.cancel();
      _showMessage('监控已暂停');
    } else {
      _startDataCollection();
      _showMessage('监控已开始');
    }
  }

  void _resetData() {
    setState(() {
      _cpuHistory.clear();
      _memoryHistory.clear();
      _networkHistory.clear();
      _connectionHistory.clear();
      _dataPointCount = 0;
    });
    _showMessage('数据已重置');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
