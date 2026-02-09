import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _titleController = TextEditingController();
  final _blockerController = TextEditingController();
  final _helpTypeController = TextEditingController();
  
  String _selectedType = '需求';
  String _selectedField = 'Web';
  String _selectedStage = '想法';
  bool _isPublicProgress = true;
  bool _loading = false;
  int _currentStep = 0;

  final List<String> _types = ['需求', '合伙', '外包'];
  final List<String> _fields = ['Web', 'IoT', 'AI', '移动开发', '其他'];
  final List<String> _stages = ['想法', '原型', '开发中', '已上线'];

  @override
  void dispose() {
    _titleController.dispose();
    _blockerController.dispose();
    _helpTypeController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (_titleController.text.isEmpty) {
      _showError('请输入项目标题');
      return;
    }

    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.createProject(
        title: _titleController.text,
        type: _selectedType,
        field: _selectedField,
        stage: _selectedStage,
        blocker: _blockerController.text.isEmpty ? null : _blockerController.text,
        helpType: _helpTypeController.text.isEmpty ? null : _helpTypeController.text,
        isPublicProgress: _isPublicProgress,
      );
      
      _showSuccess('项目创建成功');
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _createProject();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布项目'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 步骤指示器
            _buildStepIndicator(),
            const SizedBox(height: 24),
            
            // 表单内容
            Expanded(
              child: _buildStepContent(),
            ),
            
            // 底部按钮
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(0, '基本信息'),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 1 ? Colors.blue : Colors.grey[300],
          ),
        ),
        _buildStepDot(1, '项目详情'),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 2 ? Colors.blue : Colors.grey[300],
          ),
        ),
        _buildStepDot(2, '发布设置'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : isCompleted ? Colors.green : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    (step + 1).toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildSettingsStep();
      default:
        return Container();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '项目标题 *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('项目类型 *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _types.map((type) {
            return ChoiceChip(
              label: Text(type),
              selected: _selectedType == type,
              onSelected: (selected) {
                if (selected) setState(() => _selectedType = type);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('技术领域 *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _fields.map((field) {
            return ChoiceChip(
              label: Text(field),
              selected: _selectedField == field,
              onSelected: (selected) {
                if (selected) setState(() => _selectedField = field);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('项目阶段 *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _stages.map((stage) {
            return ChoiceChip(
              label: Text(stage),
              selected: _selectedStage == stage,
              onSelected: (selected) {
                if (selected) setState(() => _selectedStage = stage);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      children: [
        TextField(
          controller: _blockerController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '当前卡点（可选）',
            border: OutlineInputBorder(),
            hintText: '描述项目当前遇到的主要困难或瓶颈',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _helpTypeController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '希望获得的帮助（可选）',
            border: OutlineInputBorder(),
            hintText: '描述你希望获得什么样的帮助或合作',
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '发布设置',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('公开项目进度'),
          subtitle: const Text('其他用户可以看到项目的进度更新'),
          value: _isPublicProgress,
          onChanged: (value) {
            setState(() => _isPublicProgress = value);
          },
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '项目预览',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('标题：${'项目标题'}'),
                Text('类型：${'需求'}'),
                Text('领域：${'Web'}'),
                Text('阶段：${'想法'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _loading ? null : _previousStep,
              child: const Text('上一步'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading
                ? const CircularProgressIndicator()
                : Text(_currentStep == 2 ? '发布项目' : '下一步'),
          ),
        ),
      ],
    );
  }
}
