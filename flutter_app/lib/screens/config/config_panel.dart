import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../storage/config_manager.dart';
import '../../storage/hive_service.dart';

/// 配置面板主页面
class ConfigPanel extends StatefulWidget {
  const ConfigPanel({super.key});

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  final ConfigManager _configManager = ConfigManager.instance;
  final HiveService _hiveService = HiveService.instance;
  
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _currentConfig;
  Map<String, dynamic>? _configData;
  
  final TextEditingController _proxyController = TextEditingController();
  final TextEditingController _dnsController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializePanel();
  }
  
  Future<void> _initializePanel() async {
    try {
      // 初始化配置管理器
      await _configManager.initialize();
      await _hiveService.initialize();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
      
      // 加载当前配置
      await _loadCurrentConfig();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('初始化失败: $e');
    }
  }
  
  Future<void> _loadCurrentConfig() async {
    try {
      final config = await _configManager.loadConfigFromGo('configs/default.yaml');
      if (config != null) {
        setState(() {
          _configData = config;
          _currentConfig = 'default';
          _proxyController.text = config['proxy']?['mode'] ?? 'rule';
          _dnsController.text = '${config['dns']?['nameservers']?.join(', ') ?? ''}';
        });
      }
    } catch (e) {
      _showError('加载配置失败: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置管理'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentConfig,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showAdvancedSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isInitialized
              ? const Center(child: Text('初始化失败'))
              : _buildConfigPanel(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateConfigDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildConfigPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigSelector(),
          const SizedBox(height: 20),
          _buildProxyConfig(),
          const SizedBox(height: 20),
          _buildDnsConfig(),
          const SizedBox(height: 20),
          _buildRulesConfig(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildConfigSelector() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前配置',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _currentConfig ?? '未加载',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (String newValue) async {
                    setState(() {
                      _currentConfig = newValue;
                    });
                    await _loadConfig(newValue);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'default',
                      child: Text('默认配置'),
                    ),
                    const PopupMenuItem(
                      value: 'custom',
                      child: Text('自定义配置'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProxyConfig() {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.public, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              '代理配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _proxyController,
                  decoration: const InputDecoration(
                    labelText: '代理模式',
                    hintText: 'rule / global / direct',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '外部控制器',
                    hintText: '127.0.0.1:9090',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showProxyServersDialog,
                  icon: const Icon(Icons.list),
                  label: const Text('管理代理服务器'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDnsConfig() {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.dns, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              'DNS配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _dnsController,
                  decoration: const InputDecoration(
                    labelText: 'DNS服务器',
                    hintText: '8.8.8.8, 1.1.1.1',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('启用IPv6'),
                  value: false,
                  onChanged: (value) {
                    setState(() {
                      // 更新IPv6设置
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('使用hosts文件'),
                  value: true,
                  onChanged: (value) {
                    setState(() {
                      // 更新hosts设置
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRulesConfig() {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.rule, color: Colors.orange[600]),
            const SizedBox(width: 8),
            Text(
              '规则配置',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showRulesDialog,
                  icon: const Icon(Icons.list),
                  label: const Text('管理规则'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击管理代理规则和分流策略',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _saveConfig,
          icon: const Icon(Icons.save),
          label: const Text('保存配置'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _exportConfig,
          icon: const Icon(Icons.file_download),
          label: const Text('导出配置'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _importConfig,
          icon: const Icon(Icons.file_upload),
          label: const Text('导入配置'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[600],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  // ========== 对话框方法 ==========
  
  void _showCreateConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建新配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '配置名称',
                hintText: '输入配置名称',
              ),
            ),
            const SizedBox(height: 16),
            const Text('选择配置模板'),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('默认配置'),
              subtitle: const Text('包含基本代理和DNS设置'),
              leading: Radio(value: 'default', groupValue: null, onChanged: null),
            ),
            ListTile(
              title: const Text('空白配置'),
              subtitle: const Text('从零开始创建'),
              leading: Radio(value: 'blank', groupValue: null, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createNewConfig();
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
  
  void _showProxyServersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('代理服务器管理'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('添加代理服务器'),
                leading: const Icon(Icons.add_circle, color: Colors.green),
                onTap: () {
                  Navigator.pop(context);
                  _showAddProxyDialog();
                },
              ),
              ListTile(
                title: const Text('导入订阅链接'),
                leading: const Icon(Icons.link, color: Colors.blue),
                onTap: () {
                  Navigator.pop(context);
                  _showImportSubscriptionDialog();
                },
              ),
              ListTile(
                title: const Text('测试连接'),
                leading: const Icon(Icons.speed, color: Colors.orange),
                onTap: () {
                  Navigator.pop(context);
                  _testProxyConnections();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('规则管理'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('添加规则'),
                leading: const Icon(Icons.add_circle, color: Colors.green),
                onTap: () {
                  Navigator.pop(context);
                  _showAddRuleDialog();
                },
              ),
              ListTile(
                title: const Text('导入规则集'),
                leading: const Icon(Icons.download, color: Colors.blue),
                onTap: () {
                  Navigator.pop(context);
                  _showImportRulesDialog();
                },
              ),
              ListTile(
                title: const Text('规则排序'),
                leading: const Icon(Icons.sort, color: Colors.orange),
                onTap: () {
                  Navigator.pop(context);
                  _showRulesSortDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAdvancedSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('高级设置'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('调试模式'),
              subtitle: Text('启用详细日志输出'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('自动更新规则'),
              subtitle: Text('定期更新代理规则'),
              value: false,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('智能路由'),
              subtitle: Text('根据网络环境自动切换'),
              value: false,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  // ========== 业务逻辑方法 ==========
  
  Future<void> _loadConfig(String configName) async {
    try {
      setState(() => _isLoading = true);
      final config = await _configManager.loadConfigFromGo('configs/$configName.yaml');
      if (config != null) {
        setState(() {
          _configData = config;
        });
      }
    } catch (e) {
      _showError('加载配置失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _createNewConfig() async {
    try {
      await _configManager.createDefaultConfig();
      await _loadCurrentConfig();
      _showSuccess('新配置创建成功');
    } catch (e) {
      _showError('创建配置失败: $e');
    }
  }
  
  Future<void> _saveConfig() async {
    try {
      if (_configData == null) return;
      
      final success = await _configManager.saveConfigToGo(
        'configs/current.yaml', 
        _configData!,
      );
      
      if (success) {
        _showSuccess('配置保存成功');
      } else {
        _showError('配置保存失败');
      }
    } catch (e) {
      _showError('保存配置时出错: $e');
    }
  }
  
  Future<void> _exportConfig() async {
    try {
      final yaml = await _configManager.exportConfig(_currentConfig ?? 'current');
      if (yaml != null) {
        await Clipboard.setData(ClipboardData(text: yaml));
        _showSuccess('配置已复制到剪贴板');
      }
    } catch (e) {
      _showError('导出配置失败: $e');
    }
  }
  
  Future<void> _importConfig() async {
    // 显示导入配置对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入配置'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: '粘贴配置内容',
            hintText: 'YAML格式的配置内容',
          ),
          maxLines: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // 处理导入逻辑
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
  
  void _showAddProxyDialog() {
    // 显示添加代理服务器对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加代理服务器'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '协议类型'),
              items: const [
                DropdownMenuItem(value: 'vmess', child: Text('VMess')),
                DropdownMenuItem(value: 'vless', child: Text('VLESS')),
                DropdownMenuItem(value: 'trojan', child: Text('Trojan')),
                DropdownMenuItem(value: 'shadowsocks', child: Text('Shadowsocks')),
              ],
              onChanged: null,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: '服务器地址'),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: '端口'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: '备注名称'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  void _showAddRuleDialog() {
    // 显示添加规则对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加规则'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '规则类型'),
              items: const [
                DropdownMenuItem(value: 'DOMAIN-SUFFIX', child: Text('域名后缀')),
                DropdownMenuItem(value: 'DOMAIN-KEYWORD', child: Text('域名关键词')),
                DropdownMenuItem(value: 'DOMAIN-REGEX', child: Text('域名正则')),
                DropdownMenuItem(value: 'IP-CIDR', child: Text('IP网段')),
              ],
              onChanged: null,
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: '规则内容'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '代理组'),
              items: const [
                DropdownMenuItem(value: 'Auto', child: Text('Auto')),
                DropdownMenuItem(value: 'DIRECT', child: Text('DIRECT')),
              ],
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  void _showImportSubscriptionDialog() {
    // 显示导入订阅链接对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入订阅链接'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '订阅链接',
                hintText: 'https://example.com/subscribe',
              ),
            ),
            SizedBox(height: 12),
            CheckboxListTile(
              title: Text('自动更新'),
              subtitle: Text('定期检查订阅更新'),
              value: false,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
  
  void _showImportRulesDialog() {
    // 显示导入规则集对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入规则集'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '规则源'),
              items: const [
                DropdownMenuItem(value: 'clash', child: Text('Clash Rules')),
                DropdownMenuItem(value: 'surge', child: Text('Surge Rules')),
                DropdownMenuItem(value: 'custom', child: Text('自定义链接')),
              ],
              onChanged: null,
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: '自定义链接（可选）',
                hintText: 'https://example.com/rules.txt',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }
  
  void _showRulesSortDialog() {
    // 显示规则排序对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('规则排序'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('按类型排序'),
              leading: Icon(Icons.sort_by_alpha),
            ),
            ListTile(
              title: Text('按优先级排序'),
              leading: Icon(Icons.sort),
            ),
            ListTile(
              title: Text('手动排序'),
              leading: Icon(Icons.reorder),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _testProxyConnections() {
    // 显示代理连接测试
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('测试代理连接'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在测试代理服务器连接...'),
            SizedBox(height: 8),
            Text(
              '这可能需要几分钟时间',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    
    // 模拟测试过程
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      _showSuccess('代理连接测试完成');
    });
  }
  
  // ========== 辅助方法 ==========
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  void dispose() {
    _proxyController.dispose();
    _dnsController.dispose();
    super.dispose();
  }
}
