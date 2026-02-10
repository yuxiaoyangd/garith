import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class CreateProjectScreen extends StatefulWidget {
  final String? initialType;
  const CreateProjectScreen({super.key, this.initialType});

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

  final List<String> _projectTypes = ['需求', '合伙', '外包'];
  final List<String> _projectFields = ['Web', 'IoT', 'AI', '移动开发', '其他'];
  final List<String> _abilityFields = ['开发', '推广', '其它'];
  final List<String> _stages = ['想法', '原型', '开发中', '已上线'];

  List<String> get _currentTypes => widget.initialType == '能力' ? ['能力'] : _projectTypes;
  List<String> get _currentFields => _selectedType == '能力' ? _abilityFields : _projectFields;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
      if (_selectedType == '能力') {
        _selectedField = _abilityFields[0];
        _selectedStage = '已上线'; // Default stage for ability
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _blockerController.dispose();
    _helpTypeController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (_loading) return;
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
      
      if (!mounted) return;
      _showSuccess('项目创建成功');
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
      setState(() => _loading = false);
    }
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
        title: const Text('发布新项目'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: AppTheme.surface,
      child: Row(
        children: [
          _buildStepDot(0, '基本信息'),
          _buildStepConnector(0),
          _buildStepDot(1, '项目详情'),
          _buildStepConnector(1),
          _buildStepDot(2, '发布设置'),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isActive = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? AppTheme.primary : AppTheme.divider,
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : (isCompleted ? AppTheme.accent : AppTheme.background),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted ? Colors.transparent : AppTheme.divider,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    (step + 1).toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('项目基本信息', '请填写项目的核心信息，让大家快速了解你在做什么。'),
        const SizedBox(height: 24),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '项目标题 *',
            hintText: '一句话描述你的项目，例如：基于 Flutter 的协作平台',
          ),
        ),
        const SizedBox(height: 24),
        _buildDropdown('所属领域', _currentFields, _selectedField, (val) => setState(() => _selectedField = val!)),
        const SizedBox(height: 24),
        // 如果是能力发布，锁定类型
        IgnorePointer(
          ignoring: widget.initialType == '能力',
          child: _buildDropdown('项目类型', _currentTypes, _selectedType, (val) {
            setState(() {
              _selectedType = val!;
              // Reset field if switching types might cause mismatch (though here we only switch between project types)
              if (!_currentFields.contains(_selectedField)) {
                _selectedField = _currentFields[0];
              }
            });
          }),
        ),
        if (_selectedType != '能力') ...[
          const SizedBox(height: 24),
          _buildDropdown('当前阶段', _stages, _selectedStage, (val) => setState(() => _selectedStage = val!)),
        ],
      ],
    );
  }

  Widget _buildDetailsStep() {
    final isAbility = _selectedType == '能力';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('详细情况', isAbility ? '描述你的能力优势，让项目方找到你。' : '描述当前的困境和需求，吸引合适的合作伙伴。'),
        const SizedBox(height: 24),
        TextField(
          controller: _blockerController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: isAbility ? '能力描述' : '当前卡点（可选）',
            hintText: isAbility ? '详细描述你的技能、经验和过往案例...' : '目前遇到了什么困难？技术瓶颈、缺人、缺设计？',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _helpTypeController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: isAbility ? '期望合作方式（可选）' : '希望获得的帮助（可选）',
            hintText: isAbility ? '远程、兼职、全职？期望的薪资范围？' : '你需要什么样的伙伴？后端开发、UI设计、产品建议？',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('发布设置', '确认最后的发布选项。'),
        const SizedBox(height: 24),
        SwitchListTile(
          title: const Text('公开项目进度'),
          subtitle: const Text('开启后，所有人都可以看到你的项目更新记录，建议开启以增加透明度。'),
          value: _isPublicProgress,
          activeTrackColor: AppTheme.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (bool value) {
            setState(() {
              _isPublicProgress = value;
            });
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '预览',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Text('标题: ${_titleController.text.isEmpty ? "(未填写)" : _titleController.text}'),
              const SizedBox(height: 4),
              Text('类型: $_selectedType | $_selectedField | $_selectedStage'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(),
          items: items.map((String item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: _previousStep,
              child: const Text('上一步'),
            )
          else
            const SizedBox.shrink(),
            
          ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_currentStep == 2 ? '确认发布' : '下一步'),
          ),
        ],
      ),
    );
  }
}
