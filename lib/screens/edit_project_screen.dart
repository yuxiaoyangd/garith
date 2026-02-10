import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/project.dart';
import '../theme.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _titleController = TextEditingController();
  final _blockerController = TextEditingController();
  final _helpTypeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedType = '';
  String _selectedField = '';
  String _selectedStage = '';
  bool _isPublicProgress = true;
  bool _loading = false;
  List<String> _images = [];

  final List<String> _types = ['项目', '能力', '合伙'];
  final List<String> _fields = ['技术', '设计', '产品', '运营', '市场', '其他'];
  final List<String> _stages = ['概念', '开发中', '测试中', '已上线', '维护中'];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final project = widget.project;
    _titleController.text = project.title;
    _blockerController.text = project.blocker ?? '';
    _helpTypeController.text = project.helpType ?? '';
    
    // 确保选择的值在选项列表中
    _selectedType = _types.contains(project.type) ? project.type : _types.first;
    _selectedField = _fields.contains(project.field) ? project.field : _fields.first;
    _selectedStage = _stages.contains(project.stage) ? project.stage : _stages.first;
    
    _isPublicProgress = project.isPublicProgress;
    _images = List.from(project.images);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _blockerController.dispose();
    _helpTypeController.dispose();
    super.dispose();
  }

  Future<void> _updateProject() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.apiService.updateProject(
        widget.project.id,
        title: _titleController.text.trim(),
        type: _selectedType,
        field: _selectedField,
        stage: _selectedStage,
        blocker: _blockerController.text.trim().isEmpty ? null : _blockerController.text.trim(),
        helpType: _helpTypeController.text.trim().isEmpty ? null : _helpTypeController.text.trim(),
        images: _images,
        isPublicProgress: _isPublicProgress,
      );
      
      if (!mounted) return;
      _showSuccess('项目更新成功');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isAuthExpiredError(e)) {
        await authService.logout();
        if (!mounted) return;
        _showError('登录已过期，请重新登录');
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addImage() async {
    // 这里可以添加图片选择逻辑
    // 暂时添加一个占位符URL用于演示
    setState(() {
      _images.add('https://via.placeholder.com/300x200');
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  String _resolveImageUrl(String value) {
    if (value.startsWith('http')) return value;
    if (value.startsWith('/')) return '${ApiService.baseUrl}$value';
    return '${ApiService.baseUrl}/$value';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('编辑项目'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _updateProject,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本信息
              _buildSectionTitle('基本信息'),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '项目标题 *',
                          hintText: '给你的项目起个名字',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入项目标题';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdownField(
                        label: '项目类型 *',
                        value: _selectedType,
                        items: _types,
                        onChanged: (value) => setState(() => _selectedType = value!),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdownField(
                        label: '所属领域 *',
                        value: _selectedField,
                        items: _fields,
                        onChanged: (value) => setState(() => _selectedField = value!),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDropdownField(
                        label: '当前阶段 *',
                        value: _selectedStage,
                        items: _stages,
                        onChanged: (value) => setState(() => _selectedStage = value!),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 详细描述
              _buildSectionTitle('详细描述'),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _blockerController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '项目描述',
                          hintText: '详细描述你的项目内容、目标和现状...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _helpTypeController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '寻求帮助',
                          hintText: '说明你需要什么样的帮助或合作...',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 项目图片
              _buildSectionTitle('项目图片'),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_images.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, 
                                   size: 40, color: AppTheme.textSecondary),
                              const SizedBox(height: 8),
                              Text('暂无图片', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ] else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _images.asMap().entries.map((entry) {
                            final index = entry.key;
                            final imageUrl = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.divider),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _resolveImageUrl(imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppTheme.background,
                                          child: Icon(Icons.broken_image, 
                                               color: AppTheme.textSecondary),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, 
                                           color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addImage,
                          icon: const Icon(Icons.add),
                          label: const Text('添加图片'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 设置
              _buildSectionTitle('设置'),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('公开进度'),
                        subtitle: const Text('允许其他用户查看项目进度更新'),
                        value: _isPublicProgress,
                        onChanged: (value) => setState(() => _isPublicProgress = value),
                        activeColor: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请选择$label';
        }
        return null;
      },
    );
  }
}
