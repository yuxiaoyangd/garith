import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SubmitIntentScreen extends StatefulWidget {
  final int projectId;

  const SubmitIntentScreen({super.key, required this.projectId});

  @override
  State<SubmitIntentScreen> createState() => _SubmitIntentScreenState();
}

class _SubmitIntentScreenState extends State<SubmitIntentScreen> {
  final _offerController = TextEditingController();
  final _expectController = TextEditingController();
  final _contactController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _offerController.dispose();
    _expectController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitIntent() async {
    if (_offerController.text.isEmpty || 
        _expectController.text.isEmpty || 
        _contactController.text.isEmpty) {
      _showError('请填写所有必填项');
      return;
    }

    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.submitIntent(
        widget.projectId,
        offer: _offerController.text,
        expect: _expectController.text,
        contact: _contactController.text,
      );
      
      _showSuccess('合作意向提交成功');
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
        title: const Text('提交合作意向'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '合作意向',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请详细说明你的合作意向，项目创建者将看到你的信息。',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _offerController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '我能提供 *',
                        border: OutlineInputBorder(),
                        hintText: '描述你能为这个项目提供什么帮助、技能或资源',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _expectController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '我期望获得 *',
                        border: OutlineInputBorder(),
                        hintText: '描述你期望从这次合作中获得什么',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: '联系方式 *',
                        border: OutlineInputBorder(),
                        hintText: '邮箱、微信或其他联系方式',
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 注意事项
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '注意事项',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('• 每个用户对同一项目只能提交一次合作意向'),
                          const Text('• 项目创建者将看到你的所有信息'),
                          const Text('• 平台仅负责意向传递，不保证合作结果'),
                          const Text('• 请确保联系方式准确有效'),
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
                onPressed: _loading ? null : _submitIntent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('提交合作意向'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
