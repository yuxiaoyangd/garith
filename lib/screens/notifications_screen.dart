import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../screens/my_intents_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final notifications = await authService.apiService.getNotifications();
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载通知失败: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.markNotificationAsRead(notificationId);
      
      // 更新本地状态
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = 1;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('标记失败: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '消息通知',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无通知',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] == 1;
                      
                      return GestureDetector(
                        onTap: () => _handleNotificationTap(notification),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRead ? Colors.grey.shade200 : AppTheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.transparent : AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (notification['content'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['content'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatTime(notification['created_at']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final isRead = notification['is_read'] == 1;
    
    // 如果未读，先标记为已读
    if (!isRead) {
      await _markAsRead(notification['id']);
    }
    
    // 根据通知类型跳转到相应页面
    if (notification['type'] == 'intent_received' && notification['project_id'] != null) {
      // 跳转到项目的合作意向页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyIntentsScreen(
            projectId: notification['project_id'],
            isProjectOwnerView: true, // 作为项目所有者查看收到的意向
          ),
        ),
      );
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final time = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(time);
      
      if (diff.inDays > 0) {
        return '${diff.inDays}天前';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}小时前';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return timeStr;
    }
  }
}
