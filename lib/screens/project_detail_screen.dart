import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/project.dart';
import '../screens/submit_intent_screen.dart';
import '../screens/add_progress_screen.dart';
import '../theme.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final project = await authService.apiService.getProjectById(widget.projectId);
      if (!mounted) return;
      setState(() => _project = project);
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目详情'),
        actions: [
           if (_project != null && 
               authService.isLoggedIn && 
               _project!.ownerId == authService.currentUser!.id)
             IconButton(
               icon: const Icon(Icons.edit_note),
               tooltip: '更新进度',
               onPressed: () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProgressScreen(projectId: _project!.id),
                    ),
                  ).then((result) {
                    if (result == true) _loadProject();
                  });
               },
             ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _project == null
              ? const Center(child: Text('项目不存在'))
              : RefreshIndicator(
                  onRefresh: _loadProject,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildInfoGrid(),
                        const SizedBox(height: 24),
                        if (_project!.blocker != null) ...[
                          _buildSectionTitle('当前卡点', Icons.warning_amber_rounded, Colors.orange),
                          const SizedBox(height: 12),
                          _buildContentCard(_project!.blocker!),
                          const SizedBox(height: 24),
                        ],
                        if (_project!.helpType != null) ...[
                          _buildSectionTitle('寻求帮助', Icons.volunteer_activism, Colors.pink),
                          const SizedBox(height: 12),
                          _buildContentCard(_project!.helpType!),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionTitle('项目进度', Icons.history, AppTheme.secondary),
                        const SizedBox(height: 12),
                        if (_project!.progress.isEmpty)
                          const Text('暂无进度更新', style: TextStyle(color: AppTheme.textSecondary))
                        else
                          _buildProgressTimeline(),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _buildBottomBar(authService),
    );
  }

  Widget _buildBottomBar(AuthService authService) {
    if (_project == null || _loading) return const SizedBox.shrink();
    
    // 如果是所有者，显示管理提示或不显示
    if (authService.isLoggedIn && _project!.ownerId == authService.currentUser!.id) {
       return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: const Text(
          '你是该项目的创建者',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    // 如果未登录或非所有者，且项目活跃，显示合作按钮
    if (_project!.status == 'active') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            if (!authService.isLoggedIn) {
              _showError('请先登录');
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubmitIntentScreen(projectId: _project!.id),
              ),
            );
          },
          icon: const Icon(Icons.handshake_outlined),
          label: const Text('我有意向合作'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatusTag(_project!.status),
            const Spacer(),
            Text(
              _formatDate(_project!.createdAt),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _project!.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.divider,
              child: Icon(Icons.person, size: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              _project!.ownerNickname,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return Row(
      children: [
        Expanded(child: _buildInfoItem('领域', _project!.field)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoItem('类型', _project!.type)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoItem('阶段', _project!.stage)),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value, 
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 15,
          color: AppTheme.textPrimary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildProgressTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _project!.progress.length,
      itemBuilder: (context, index) {
        final progress = _project!.progress[index];
        final isLast = index == _project!.progress.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: AppTheme.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(progress.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progress.content,
                              style: const TextStyle(height: 1.5),
                            ),
                            if (progress.summary != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.secondary.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '💡 小结',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      progress.summary!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTag(String status) {
    Color color;
    String text;
    switch (status) {
      case 'active':
        color = AppTheme.accent;
        text = '进行中';
        break;
      case 'paused':
        color = Colors.amber;
        text = '暂停';
        break;
      case 'closed':
        color = AppTheme.textSecondary;
        text = '已结束';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
