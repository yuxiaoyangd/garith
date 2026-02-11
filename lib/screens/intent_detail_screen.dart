import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 项目信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work_outline, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '项目',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.projectTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 发送者信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '发送者',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      intent['nickname'] ?? '未知用户',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      intent['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 合作提供内容
            _buildContentCard(
              title: '我能提供',
              icon: Icons.handshake_outlined,
              content: intent['offer'] ?? '',
            ),
            
            const SizedBox(height: 16),
            
            // 期望获得内容
            _buildContentCard(
              title: '我期望',
              icon: Icons.star_outline,
              content: intent['expect'] ?? '',
            ),
            
            const SizedBox(height: 16),
            
            // 联系方式
            _buildContentCard(
              title: '联系方式',
              icon: Icons.contact_mail_outlined,
              content: intent['contact'] ?? '',
            ),
            
            const SizedBox(height: 16),
            
            // 状态和时间信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '状态',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildStatusChip(intent['status'] ?? 'submitted'),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '提交时间',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(intent['created_at']),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 操作按钮（仅项目所有者可见）
            if (isOwner && intent['status'] == 'submitted') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _updating ? null : () => _updateStatus('closed'),
                      icon: const Icon(Icons.close),
                      label: const Text('拒绝'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _updating ? null : () => _updateStatus('viewed'),
                      icon: const Icon(Icons.check),
                      label: const Text('接受'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildContentCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Text(
                content.isEmpty ? '未填写' : content,
                style: TextStyle(
                  fontSize: 14,
                  color: content.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'submitted':
        color = AppTheme.accent;
        text = '待处理';
        break;
      case 'viewed':
        color = AppTheme.primary;
        text = '已接受';
        break;
      case 'closed':
        color = AppTheme.error;
        text = '已拒绝';
        break;
      default:
        color = AppTheme.textSecondary;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return '未知';
    
    try {
      DateTime date;
      if (dateInput is DateTime) {
        date = dateInput;
      } else if (dateInput is String) {
        date = DateTime.parse(dateInput);
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
