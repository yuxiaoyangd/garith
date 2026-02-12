import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../utils/date_time_utils.dart';

class IntentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> intent;
  final String projectTitle;

  const IntentDetailScreen({
    super.key,
    required this.intent,
    required this.projectTitle,
  });

  @override
  State<IntentDetailScreen> createState() => _IntentDetailScreenState();
}

class _IntentDetailScreenState extends State<IntentDetailScreen> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final intent = widget.intent;
    final isOwner = _isProjectOwner();
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('合作意向详情'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 项目标题
            Text(
              widget.projectTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '提交于 ${_formatDate(intent['created_at'])}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 合作提供内容
            _buildSection(
              title: '我能提供',
              content: intent['offer'] ?? '',
            ),
            
            const SizedBox(height: 24),
            
            // 期望获得内容
            _buildSection(
              title: '我期望',
              content: intent['expect'] ?? '',
            ),
            
            const SizedBox(height: 24),
            
            // 联系方式
            _buildSection(
              title: '联系方式',
              content: intent['contact'] ?? '',
            ),
            
            const SizedBox(height: 40),
            
            // 操作按钮（仅项目所有者可见且状态为 submitted）
            if (isOwner && intent['status'] == 'submitted') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _updating ? null : () => _updateStatus('closed'),
                      icon: const Icon(Icons.close),
                      label: const Text('拒绝'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _updating ? null : () => _updateStatus('viewed'),
                      icon: const Icon(Icons.check),
                      label: const Text('接受'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isProjectOwner() {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.isLoggedIn && 
           authService.currentUser != null &&
           widget.intent['project_owner_id'] == authService.currentUser!.id;
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
          ),
          child: SelectableText(
            content.isEmpty ? '未填写' : content,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: content.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return '未知';
    
    try {
      DateTime date;
      if (dateInput is DateTime) {
        date = dateInput;
      } else if (dateInput is String) {
        date = parseServerDateTime(dateInput);
      } else {
        return '未知';
      }
      
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateInput.toString();
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.updateIntentStatus(
        widget.intent['project_id'],
        widget.intent['id'],
        status,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'viewed' ? '已接受合作意向' : '已拒绝合作意向'),
            backgroundColor: status == 'viewed' ? AppTheme.primary : AppTheme.error,
          ),
        );
        Navigator.pop(context, true); // 返回时刷新列表
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }
}
