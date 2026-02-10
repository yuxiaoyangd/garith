import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/searchable_dropdown.dart';
import '../constants.dart';

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

  String _selectedType = '求资';
  String _selectedField = 'Web应用';
  String _selectedStage = '想法';
  bool _isPublicProgress = true;
  bool _loading = false;
  int _currentStep = 0;
  List<XFile> _selectedImages = [];

  bool get _isAbility => widget.initialType == '能力';

  Map<String, List<String>> get _currentFieldsGrouped =>
      _isAbility ? AppConstants.abilityFieldsGrouped : AppConstants.projectFieldsGrouped;

  List<String> get _currentFieldsFlat =>
      _isAbility ? AppConstants.abilityFieldsFlat : AppConstants.projectFieldsFlat;

  @override
  void initState() {
    super.initState();
    if (_isAbility) {
      _selectedType = '能力';
      _selectedStage = AppConstants.stages.last;
      _selectedField = AppConstants.abilityFieldsGrouped.values.first.first;
      return;
    }

    // 项目默认值
    _selectedType = AppConstants.projectTypes.first;
    if (!_currentFieldsFlat.contains(_selectedField)) {
      _selectedField = AppConstants.projectFieldsGrouped.values.first.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _blockerController.dispose();
    _helpTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (images != null && images.isNotEmpty) {
      setState(() {
        _selectedImages = images.take(5).toList(); // 最多5张图片
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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

      List<String> uploadedImages = [];

      // 先上传图片（如果有的话）
      if (_selectedImages.isNotEmpty) {
        try {
          uploadedImages = await authService.apiService.uploadProjectImages(
            _selectedImages.map((xfile) => xfile.path).toList(),
          );
        } catch (uploadError) {
          debugPrint('Image upload failed: $uploadError');
          // 图片上传失败不阻止项目创建，继续创建项目
        }
      }

      // 创建项目
      await authService.apiService.createProject(
        title: _titleController.text,
        type: _selectedType,
        field: _selectedField,
        stage: _selectedStage,
        blocker: _blockerController.text.isEmpty
            ? null
            : _blockerController.text,
        helpType: _helpTypeController.text.isEmpty
            ? null
            : _helpTypeController.text,
        images: uploadedImages.isNotEmpty ? uploadedImages : null,
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

  Future<bool> _showExitConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出后已填写的内容将被清空，确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

@override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final hasContent = _titleController.text.isNotEmpty ||
            _blockerController.text.isNotEmpty ||
            _helpTypeController.text.isNotEmpty;
        
        if (hasContent) {
          final shouldPop = await _showExitConfirmDialog();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        } else {
          if (mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_isAbility ? '展示能力' : '发布项目'),
          backgroundColor: AppTheme.surface,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildStepIndicator(),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          _buildStepDot(0, _isAbility ? '基本信息' : '项目信息'),
          _buildStepConnector(0),
          _buildStepDot(1, _isAbility ? '能力详情' : '项目详情'),
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
            color: isActive
                ? AppTheme.primary
                : (isCompleted ? AppTheme.accent : AppTheme.background),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted
                  ? Colors.transparent
                  : AppTheme.divider,
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
    final isAbility = _isAbility;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          isAbility ? '能力基本信息' : '项目基本信息',
          isAbility ? '请填写你的核心能力，让大家快速了解你的技能优势。' : '请填写项目的核心信息，让大家快速了解你在做什么。',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: isAbility ? '能力名称 *' : '项目标题 *',
            hintText: isAbility
                ? '一句话描述你的能力，例如：全栈开发工程师'
                : '一句话描述你的项目，例如：基于 Flutter 的协作平台',
          ),
        ),
        const SizedBox(height: 24),
        SearchableDropdown(
          label: '所属领域',
          value: _selectedField,
          groupedItems: _currentFieldsGrouped,
          onChanged: (val) {
            if (val != null) setState(() => _selectedField = val);
          },
        ),

        if (!isAbility) ...[
          const SizedBox(height: 24),
          SearchableDropdown(
            label: '需求类型',
            value: _selectedType,
            items: AppConstants.projectTypes,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedType = val);
              }
            },
          ),
        ],

        const SizedBox(height: 24),
        if (!isAbility)
          SearchableDropdown(
            label: '当前阶段',
            value: _selectedStage,
            items: AppConstants.stages,
            onChanged: (val) {
              if (val != null) setState(() => _selectedStage = val);
            },
          ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final isAbility = _isAbility;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          '详细情况',
          isAbility ? '描述你的能力优势，让项目方找到你。' : '描述当前的困境和需求，吸引合适的合作伙伴。',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _blockerController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: isAbility ? '能力描述' : '项目描述（可选）',
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
        const SizedBox(height: 24),
        // 图片上传区域
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '项目图片（可选）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '最多上传5张图片，展示你的项目或能力',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 48, color: AppTheme.textSecondary),
                      SizedBox(height: 8),
                      Text(
                        '点击选择图片',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  Container(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          // 添加更多图片按钮
                          return GestureDetector(
                            onTap: _selectedImages.length < 5 ? _pickImages : null,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: const Icon(Icons.add, color: AppTheme.textSecondary),
                            ),
                          );
                        }
                        
                        // 显示选中的图片
                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(_selectedImages[index].path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedImages.length}/5',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsStep() {
    final isAbility = _isAbility;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('发布设置', '确认最后的发布选项。'),
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text(isAbility ? '公开能力信息' : '公开项目进度'),
          subtitle: Text(
            isAbility
                ? '开启后，所有人都可以看到你的能力详情，建议开启以增加曝光。'
                : '开启后，所有人都可以看到你的项目更新记录，建议开启以增加透明度。',
          ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '标题: ${_titleController.text.isEmpty ? "(未填写)" : _titleController.text}',
              ),
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
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
            OutlinedButton(onPressed: _previousStep, child: const Text('上一步'))
          else
            const SizedBox.shrink(),

          ElevatedButton(
            onPressed: _loading ? null : _nextStep,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_currentStep == 2 ? '确认发布' : '下一步'),
          ),
        ],
      ),
    );
  }
}
