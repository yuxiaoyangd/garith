import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AddProgressSimpleScreen extends StatefulWidget {
  final int projectId;

  const AddProgressSimpleScreen({super.key, required this.projectId});

  @override
  State<AddProgressSimpleScreen> createState() => _AddProgressSimpleScreenState();
}

class _AddProgressSimpleScreenState extends State<AddProgressSimpleScreen> {
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
    if (_loading) return;
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
      
      if (!mounted) return;
      _showSuccess('进度添加成功');
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
        title: const Text('新增进度记录'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '记录项目进展',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '分享项目的最新进展，让合作者了解项目状态。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _contentController,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: '进度内容 *',
                              hintText: '详细描述这次的进度更新，比如完成了什么功能、解决了什么问题等...',
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '请输入进度内容';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          TextFormField(
                            controller: _summaryController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: '一句话小结（可选）',
                              hintText: '例如：完成了核心支付模块开发',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        '温馨提示',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                      ),
                                      SizedBox(height: 4),
                                      Text('进度记录添加后不可编辑或删除，请按实际情况添加', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _addProgress,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('提交进度'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
