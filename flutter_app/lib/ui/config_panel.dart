// config_panel.dart - 配置管理面板UI
// 用户友好的配置管理界面，支持实时预览和验证

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import '../bridge/config_manager.dart';
import '../bridge/mihomo_ffi.dart';

/// 配置管理面板页面
class ConfigPanelPage extends StatefulWidget {
  const ConfigPanelPage({Key? key}) : super(key: key);

  @override
  State<ConfigPanelPage> createState() => _ConfigPanelPageState();
}

class _ConfigPanelPageState extends State<ConfigPanelPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // 配置管理器
  final configManager = ConfigManager();

  // 状态管理
  bool _isInitialized = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _configs = [];
  Map<String, dynamic>? _currentConfig;
  String _currentConfigId = '';
  String _currentConfigName = '';

  // 编辑器状态
  final TextEditingController _configEditorController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();

  // 验证状态
  bool _isValidating = false;
  String _validationError = '';
  List<String> _validationWarnings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeConfigManager();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _configEditorController.dispose();
    _scrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  // =============================================================================
  // 初始化和加载
  // =============================================================================

  Future<void> _initializeConfigManager() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await configManager.initialize();
      if (success) {
        await _loadAllConfigs();
        setState(() {
          _isInitialized = true;
        });
      } else {
        _showErrorSnackBar('配置管理器初始化失败');
      }
    } catch (e) {
      _showErrorSnackBar('初始化错误: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllConfigs() async {
    final result = await configManager.getAllConfigs();
    if (result['success']) {
      setState(() {
        _configs = List<Map<String, dynamic>>.from(result['configs']);
      });
    } else {
      _showErrorSnackBar('加载配置列表失败: ${result['error']}');
    }
  }

  // =============================================================================
  // 配置操作
  // =============================================================================

  Future<void> _createNewConfig() async {
    final name = await _showNameDialog('新建配置', '配置名称');
    if (name == null || name.trim().isEmpty) return;

    final newConfig = {
      'version': 'v1',
      'proxy': {
        'mode': 'Rule',
        'allow-lan': false,
        'bind-address': '0.0.0.0',
        'servers': [],
        'groups': [],
      },
      'dns': {
        'enable': true,
        'nameserver': ['8.8.8.8', '8.8.4.4'],
        'fallback': ['114.114.114.114'],
      },
      'rules': [
        {'type': 'MATCH', 'value': ''}
      ],
    };

    final result = await configManager.saveConfig(
      name: name.trim(),
      config: newConfig,
      description: '新建的配置',
    );

    if (result['success']) {
      await _loadAllConfigs();
      await _loadConfig(result['data']['id']);
      _showSuccessSnackBar('配置创建成功');
    } else {
      _showErrorSnackBar('创建配置失败: ${result['error']}');
    }
  }

  Future<void> _loadConfig(String configId) async {
    final result = await configManager.loadConfig(configId);
    if (result['success']) {
      final configData = result['data'];
      setState(() {
        _currentConfig = configData['config'];
        _currentConfigId = configId;
        _currentConfigName = configData['name'];
        _configEditorController.text = _formatConfigAsYaml(configData['config']);
      });
    } else {
      _showErrorSnackBar('加载配置失败: ${result['error']}');
    }
  }

  Future<void> _saveConfig() async {
    if (_currentConfigId.isEmpty) {
      _showErrorSnackBar('请先选择一个配置');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 解析编辑器中的配置
      final yamlContent = _configEditorController.text;
      final configData = await _parseYamlConfig(yamlContent);

      if (configData == null) {
        _showErrorSnackBar('配置格式错误，请检查YAML语法');
        return;
      }

      final result = await configManager.saveConfig(
        name: _currentConfigName,
        config: configData,
        description: '从编辑器保存',
        metadata: {'last_edited': DateTime.now().toIso8601String()},
      );

      if (result['success']) {
        await _loadAllConfigs();
        _showSuccessSnackBar('配置保存成功');
      } else {
        _showErrorSnackBar('保存配置失败: ${result['error']}');
      }
    } catch (e) {
      _showErrorSnackBar('保存错误: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteConfig(String configId, String configName) async {
    final confirmed = await _showConfirmDialog(
      '删除配置',
      '确定要删除配置 "$configName" 吗？此操作不可撤销。',
    );

    if (!confirmed) return;

    final result = await configManager.deleteConfig(configId);
    if (result['success']) {
      await _loadAllConfigs();
      if (_currentConfigId == configId) {
        _clearCurrentConfig();
      }
      _showSuccessSnackBar('配置删除成功');
    } else {
      _showErrorSnackBar('删除配置失败: ${result['error']}');
    }
  }

  // =============================================================================
  // 导入导出
  // =============================================================================

  Future<void> _importConfig() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['yaml', 'yml'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final fileName = result.files.first.name;

      final name = await _showNameDialog('导入配置', '配置名称', defaultValue: fileName.replaceAll(RegExp(r'\.(yaml|yml)$'), ''));
      if (name == null || name.trim().isEmpty) return;

      final importResult = await configManager.importConfigFromYAML(
        yamlContent: content,
        name: name.trim(),
        description: '从文件导入: ${result.files.first.name}',
      );

      if (importResult['success']) {
        await _loadAllConfigs();
        await _loadConfig(importResult['data']['id']);
        _showSuccessSnackBar('配置导入成功');
      } else {
        _showErrorSnackBar('导入配置失败: ${importResult['error']}');
      }
    }
  }

  Future<void> _exportConfig() async {
    if (_currentConfigId.isEmpty) {
      _showErrorSnackBar('请先选择一个配置');
      return;
    }

    final result = await configManager.exportConfigToYAML(_currentConfigId);
    if (result['success']) {
      _showSuccessSnackBar('配置已导出到: ${result['path']}');
    } else {
      _showErrorSnackBar('导出配置失败: ${result['error']}');
    }
  }

  // =============================================================================
  // 验证功能
  // =============================================================================

  Future<void> _validateConfig() async {
    setState(() {
      _isValidating = true;
      _validationError = '';
      _validationWarnings.clear();
    });

    try {
      final yamlContent = _configEditorController.text;
      final configData = await _parseYamlConfig(yamlContent);

      if (configData == null) {
        setState(() {
          _validationError = 'YAML语法错误，请检查配置格式';
        });
        return;
      }

      // 基本验证
      final warnings = <String>[];

      if (!configData.containsKey('proxy')) {
        warnings.add('缺少proxy配置');
      }

      if (configData['proxy'] != null) {
        final proxy = configData['proxy'];
        if (proxy['servers'] == null || (proxy['servers'] as List).isEmpty) {
          warnings.add('代理服务器列表为空');
        }

        if (proxy['mode'] == null) {
          warnings.add('未指定代理模式');
        }
      }

      setState(() {
        _validationWarnings = warnings;
        _validationError = warnings.isEmpty ? '配置验证通过' : '配置验证完成，发现 ${warnings.length} 个警告';
      });

    } catch (e) {
      setState(() {
        _validationError = '验证过程出错: $e';
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  // =============================================================================
  // 辅助方法
  // =============================================================================

  String _formatConfigAsYaml(Map<String, dynamic> config) {
    return _yamlEncode(config, 0);
  }

  String _yamlEncode(dynamic data, int indent) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    if (data is Map) {
      for (var entry in data.entries) {
        if (entry.value is Map || entry.value is List) {
          buffer.writeln('$indentStr${entry.key}:');
          buffer.write(_yamlEncode(entry.value, indent + 1));
        } else if (entry.value is String) {
          buffer.writeln('$indentStr${entry.key}: "${entry.value}"');
        } else {
          buffer.writeln('$indentStr${entry.key}: ${entry.value}');
        }
      }
    } else if (data is List) {
      for (var item in data) {
        if (item is Map || item is List) {
          buffer.writeln('${indentStr}-');
          buffer.write(_yamlEncode(item, indent + 1));
        } else {
          buffer.writeln('$indentStr- $item');
        }
      }
    }

    return buffer.toString();
  }

  Future<Map<String, dynamic>?> _parseYamlConfig(String yamlContent) async {
    try {
      final doc = loadYamlDocument(yamlContent);
      return _yamlToJson(doc.contents);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> _yamlToJson(YamlNode node) {
    if (node is YamlMap) {
      final result = <String, dynamic>{};
      for (var entry in node.nodes.entries) {
        result[entry.key.value.toString()] = _yamlToJson(entry.value);
      }
      return result;
    } else if (node is YamlList) {
      return node.nodes.map((item) => _yamlToJson(item)).toList();
    } else if (node is YamlScalar) {
      return node.value;
    }
    return {};
  }

  void _clearCurrentConfig() {
    setState(() {
      _currentConfig = null;
      _currentConfigId = '';
      _currentConfigName = '';
      _configEditorController.clear();
    });
  }

  Future<String?> _showNameDialog(String title, String label, {String? defaultValue}) async {
    final controller = TextEditingController(text: defaultValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    ) ?? false;
  }

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

  // =============================================================================
  // 构建UI
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在初始化配置管理器...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('配置管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: '配置列表'),
            Tab(icon: Icon(Icons.edit), text: '配置编辑'),
            Tab(icon: Icon(Icons.settings), text: '应用设置'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllConfigs,
            tooltip: '刷新配置列表',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewConfig,
            tooltip: '新建配置',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importConfig,
            tooltip: '导入配置',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConfigListTab(),
          _buildConfigEditorTab(),
          _buildSettingsTab(),
        ],
      ),
      floatingActionButton: _currentConfigId.isNotEmpty
          ? FloatingActionButton(
              onPressed: _saveConfig,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildConfigListTab() {
    return Column(
      children: [
        _buildConfigListHeader(),
        Expanded(
          child: _configs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无配置',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '点击 + 按钮创建新配置或导入配置文件',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _configs.length,
                  itemBuilder: (context, index) {
                    final config = _configs[index];
                    final isSelected = config['id'] == _currentConfigId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 8 : 2,
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.blue : Colors.grey,
                          child: Text(
                            config['name'].toString().substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          config['name'],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '创建: ${_formatDateTime(config['created'])}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '修改: ${_formatDateTime(config['modified'])}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            switch (value) {
                              case 'load':
                                await _loadConfig(config['id']);
                                break;
                              case 'edit':
                                await _loadConfig(config['id']);
                                _tabController.animateTo(1);
                                break;
                              case 'export':
                                await configManager.exportConfigToYAML(config['id']);
                                break;
                              case 'delete':
                                await _deleteConfig(config['id'], config['name']);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'load',
                              child: ListTile(
                                leading: Icon(Icons.play_arrow),
                                title: Text('加载'),
                                dense: true,
                              ),
 PopupMenuItem(
                              value: '                            ),
                            constedit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('编辑'),
                                dense: true,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'export',
                              child: ListTile(
                                leading: Icon(Icons.file_download),
                                title: Text('导出'),
                                dense: true,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('删除', style: TextStyle(color: Colors.red)),
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _loadConfig(config['id']),
                        selected: isSelected,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConfigListHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Icon(Icons.list, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '配置列表 (${_configs.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '当前: ${_currentConfigName.isNotEmpty ? _currentConfigName : '未选择'}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigEditorTab() {
    return Column(
      children: [
        _buildEditorHeader(),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _configEditorController,
              focusNode: _editorFocusNode,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                hintText: '配置内容将显示在这里...',
              ),
              maxLines: null,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ),
        _buildValidationPanel(),
      ],
    );
  }

  Widget _buildEditorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            _currentConfigName.isNotEmpty ? '编辑: $_currentConfigName' : '配置编辑器',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _validateConfig,
            icon: _isValidating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: const Text('验证'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _exportConfig,
            icon: const Icon(Icons.file_download),
            label: const Text('导出'),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationPanel() {
    if (_validationError.isEmpty && _validationWarnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _validationError.contains('通过') ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: _validationError.contains('通过') ? Colors.green.shade300 : Colors.orange.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _validationError.contains('通过') ? Icons.check_circle : Icons.warning,
                color: _validationError.contains('通过') ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _validationError.isNotEmpty
                      ? _validationError
                      : '配置验证完成',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _validationError.contains('通过') ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (_validationWarnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('警告:'),
            for (final warning in _validationWarnings)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $warning'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection(
          '配置管理',
          [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('备份所有配置'),
              subtitle: const Text('将所有配置导出为备份文件'),
              onTap: () async {
                final directory = await getApplicationDocumentsDirectory();
                final result = await configManager.backupConfigs('${directory.path}/backups');
                if (result['success']) {
                  _showSuccessSnackBar('备份完成: ${result['path']}');
                } else {
                  _showErrorSnackBar('备份失败: ${result['error']}');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('清理过期配置'),
              subtitle: const Text('删除30天前修改的配置'),
              onTap: () async {
                final result = await configManager.cleanupExpiredConfigs();
                if (result['success']) {
                  await _loadAllConfigs();
                  _showSuccessSnackBar('清理了 ${result['cleaned']} 个过期配置');
                } else {
                  _showErrorSnackBar('清理失败: ${result['error']}');
                }
              },
            ),
          ],
        ),
        _buildSettingsSection(
          '编辑器设置',
          [
            SwitchListTile(
              title: const Text('自动保存'),
              subtitle: const Text('编辑时自动保存配置'),
              value: true,
              onChanged: (value) {
                // TODO: 实现自动保存设置
              },
            ),
            SwitchListTile(
              title: const Text('实时验证'),
              subtitle: const Text('编辑时实时验证配置格式'),
              value: true,
              onChanged: (value) {
                // TODO: 实现实时验证设置
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
