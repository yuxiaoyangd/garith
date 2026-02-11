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
  final List<String> _stages = ['想法', '原型', '开发中', '已上线'];

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
      
      // 模拟延迟，提升交互质感
      // await Future.delayed(const Duration(milliseconds: 500)); 

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
      Navigator.pop(context, true);
      _showSuccess('项目更新成功');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ... (保持原有的图片添加/删除逻辑不变)
  void _addImage() {
    setState(() {
      _images.add('https://via.placeholder.com/300x200'); // 模拟添加
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
      SnackBar(content: Text(message), backgroundColor: AppTheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          '编辑项目',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _loading ? null : _updateProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // 1. 标题输入 (大字号，无边框风格)
            TextFormField(
              controller: _titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '输入项目标题',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.zero,
              ),
              validator: (v) => v?.trim().isEmpty == true ? '请输入标题' : null,
            ),
            const SizedBox(height: 24),

            // 2. 核心属性选择 (使用标签组 Chips)
            _buildSectionLabel('项目类型'),
            _buildChoiceChipGroup(_types, _selectedType, (val) => setState(() => _selectedType = val)),
            
            const SizedBox(height: 24),

            // 3. 分类与阶段 (使用底部弹窗选择器，比原生Dropdown好看)
            Row(
              children: [
                Expanded(
                  child: _buildSelectTile(
                    label: '所属领域',
                    value: _selectedField,
                    onTap: () => _showPicker('选择领域', _fields, (val) => setState(() => _selectedField = val)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelectTile(
                    label: '当前阶段',
                    value: _selectedStage,
                    onTap: () => _showPicker('选择阶段', _stages, (val) => setState(() => _selectedStage = val)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 4. 详细描述区域 (背景色块风格)
            _buildSectionLabel('详细信息'),
            const SizedBox(height: 8),
            _buildTextArea(
              controller: _blockerController,
              hint: '描述项目目标、现状、你需要做什么...',
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextArea(
              controller: _helpTypeController,
              hint: '你需要什么样的帮助？例如：寻找React开发者...',
              icon: Icons.volunteer_activism_outlined,
              isHighlight: true, // 高亮显示
            ),

            const SizedBox(height: 32),

            // 5. 图片上传 (Grid风格)
            _buildSectionLabel('展示图片'),
            const SizedBox(height: 12),
            _buildImageGrid(),

            const SizedBox(height: 32),

            // 6. 开关设置
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('公开项目进度', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('允许访客查看时间轴动态', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                value: _isPublicProgress,
                onChanged: (val) => setState(() => _isPublicProgress = val),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI 组件封装 ---

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  // 胶囊选择组 (Chips)
  Widget _buildChoiceChipGroup(List<String> items, String selected, Function(String) onSelected) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = selected == item;
        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onSelected(item),
          selectedColor: AppTheme.primary.withValues(alpha: 0.1),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  // 模拟下拉选择框
  Widget _buildSelectTile({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 多行文本域
  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? AppTheme.primary.withValues(alpha: 0.03) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: isHighlight ? Border.all(color: AppTheme.primary.withValues(alpha: 0.1)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: isHighlight ? AppTheme.primary : AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                isHighlight ? '寻求帮助' : '项目描述',
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(height: 1.5, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              isDense: true,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // 图片网格
  Widget _buildImageGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算宽度，一行显示3-4个
        final double itemSize = (constraints.maxWidth - 20) / 3; 
        
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._images.asMap().entries.map((entry) {
              return Stack(
                children: [
                  Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(_resolveImageUrl(entry.value)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }),
            // 添加按钮
            InkWell(
              onTap: _addImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none), // 使用虚线包或自定义CustomPainter会更好，这里简化为灰色背景
                ),
                child: DottedBorderContainer( // 自定义虚线组件
                  child: const Center(
                    child: Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 底部选择弹窗
  void _showPicker(String title, List<String> items, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(items[index], textAlign: TextAlign.center),
                      onTap: () {
                        onSelect(items[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 简单的虚线边框容器
class DottedBorderContainer extends StatelessWidget {
  final Widget child;
  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: child,
    );
  }
}