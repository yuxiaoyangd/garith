import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AddProgressScreen extends StatefulWidget {
  final int projectId;

  const AddProgressScreen({super.key, required this.projectId});

  @override
  State<AddProgressScreen> createState() => _AddProgressScreenState();
}

class _AddProgressScreenState extends State<AddProgressScreen> {
  final _contentController = TextEditingController();
  final _summaryController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _addProgress() async {
    if (_contentController.text.isEmpty) {
      _showError('请输入进度内容');
      return;
    }

    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.addProgress(
        widget.projectId,
        _contentController.text,
        summary: _summaryController.text.isEmpty ? null : _summaryController.text,
      );
      
      _showSuccess('进度添加成功');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更新项目进度'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '项目进度',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '记录项目的最新进展，让合作者了解项目状态。',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: '进度内容 *',
                        border: OutlineInputBorder(),
                        hintText: '详细描述这次的进度更新，比如完成了什么功能、解决了什么问题等',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _summaryController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '阶段性小结（可选）',
                        border: OutlineInputBorder(),
                        hintText: '总结这次进度的重要成果或变化',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 注意事项
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '注意事项',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('• 进度一旦提交不可修改或删除'),
                          Text('• 请确保内容真实准确'),
                          Text('• 定期更新进度有助于吸引合作者'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 提交按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _addProgress,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('提交进度'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
