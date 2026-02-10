import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

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
    if (_loading) return;
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
      
      if (!mounted) return;
      _showSuccess('合作意向提交成功');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('提交合作意向'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '发起合作',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '真诚的沟通是合作的第一步。项目创建者将直接看到您的留言。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  TextField(
                    controller: _offerController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '我能提供 *',
                      hintText: '描述你能为这个项目提供什么帮助、技能或资源...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _expectController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '我期望获得 *',
                      hintText: '描述你期望从这次合作中获得什么回报...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: '联系方式 *',
                      hintText: '微信 / 邮箱 / 手机号',
                      prefixIcon: Icon(Icons.contact_mail_outlined),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: AppTheme.secondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '隐私说明',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                              ),
                              SizedBox(height: 4),
                              Text('您的联系方式仅对项目创建者可见，平台不会公开展示。', style: TextStyle(fontSize: 13)),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitIntent,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('发送意向'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
