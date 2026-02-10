import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/project.dart';
import '../screens/project_detail_screen.dart';
import '../screens/project_intents_screen.dart';
import '../theme.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  List<Project> _projects = [];
  bool _loading = true;
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final projects = await authService.getMyProjects(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );
      setState(() => _projects = projects);
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

  Future<void> _updateProjectStatus(int projectId, String newStatus) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.updateProjectStatus(projectId, newStatus);
      if (!mounted) return;
      _showSuccess('项目状态已更新');
      _loadProjects();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  Future<void> _deleteProject(int projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除这个项目吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.apiService.deleteProject(projectId);
      if (!mounted) return;
      _showSuccess('项目已删除');
      _loadProjects();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accent),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的项目'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              children: [
                const Text('状态筛选:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 8,
                      children: ['全部', 'active', 'paused', 'closed'].map((status) {
                        final isSelected = _selectedStatus == (status == '全部' ? '' : status);
                        return ChoiceChip(
                          label: Text(status == '全部' ? '全部' : _getStatusText(status)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = (status == '全部' || !selected) ? '' : status;
                            });
                            _loadProjects();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            const Text('你还没有发布任何项目'),
                            const SizedBox(height: 24),
                            // 这里可以加一个去创建的按钮，但考虑到导航栈，暂不加
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProjects,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _projects.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final project = _projects[index];
                            return _buildProjectCard(project);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return '进行中';
      case 'paused': return '已暂停';
      case 'closed': return '已结束';
      default: return status;
    }
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          ).then((_) => _loadProjects());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _buildStatusBadge(project.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(Icons.update, '${project.progressCount ?? 0} 次更新'),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.people_outline, '${project.intentsCount ?? 0} 个意向'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '更新于 ${_formatDate(project.updatedAt)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectIntentsScreen(
                            projectId: project.id,
                            projectTitle: project.title,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text('查看意向 (${project.intentsCount ?? 0})'),
                  ),
                  const SizedBox(width: 8),
                  if (project.status != 'closed') ...[
                    TextButton(
                      onPressed: () {
                        final newStatus = project.status == 'active' ? 'paused' : 'active';
                        _updateProjectStatus(project.id, newStatus);
                      },
                      child: Text(project.status == 'active' ? '暂停' : '恢复'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => _deleteProject(project.id),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                    child: const Text('删除'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
