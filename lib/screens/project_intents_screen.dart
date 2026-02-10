import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/intent.dart' as models;
import '../theme.dart';

class ProjectIntentsScreen extends StatefulWidget {
  final int projectId;
  final String projectTitle;

  const ProjectIntentsScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ProjectIntentsScreen> createState() => _ProjectIntentsScreenState();
}

class _ProjectIntentsScreenState extends State<ProjectIntentsScreen> {
  List<models.Intent> _intents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIntents();
  }

  Future<void> _loadIntents() async {
    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final intents = await authService.apiService.getProjectIntents(widget.projectId);
      if (!mounted) return;
      setState(() => _intents = intents);
    } catch (e) {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isAuthExpiredError(e)) {
        await authService.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登录已过期，请重新登录'), backgroundColor: AppTheme.error),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsViewed(models.Intent intent) async {
    if (intent.status != 'submitted') return;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.updateIntentStatus(widget.projectId, intent.id, 'viewed');
      // 局部更新状态
      setState(() {
        final index = _intents.indexWhere((i) => i.id == intent.id);
        if (index != -1) {
          // 由于Intent是immutable的，这里可能需要重新加载或者忽略（因为我们没有CopyWith方法）
          // 简单起见，重新加载列表或者手动忽略更新UI，只要后端更新了即可。
          // 为了更好的体验，我们重新加载列表
          _loadIntents();
        }
      });
    } catch (e) {
      // 忽略错误
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(widget.projectTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '收到的合作意向',
              style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8)),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _intents.isEmpty
              ? const Center(child: Text('暂无意向提交'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _intents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final intent = _intents[index];
                    return _buildIntentCard(intent);
                  },
                ),
    );
  }

  Widget _buildIntentCard(models.Intent intent) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                (intent.userNickname ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intent.userNickname ?? '未知用户',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    intent.userEmail ?? '',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            if (intent.status == 'submitted')
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onExpansionChanged: (expanded) {
          if (expanded && intent.status == 'submitted') {
            _markAsViewed(intent);
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildSection('提供的资源 (Offer)', intent.offer),
                const SizedBox(height: 12),
                _buildSection('期望的回报 (Expect)', intent.expect),
                const SizedBox(height: 12),
                _buildSection('联系方式', intent.contact),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '提交时间: ${_formatDate(intent.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(content),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
