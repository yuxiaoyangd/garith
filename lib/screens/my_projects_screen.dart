import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/project.dart';
import '../screens/project_detail_screen.dart';
import '../screens/add_progress_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的项目'),
      ),
      body: Column(
        children: [
          // 状态筛选
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('状态筛选', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['全部', 'active', 'paused', 'closed'].map((status) {
                    return FilterChip(
                      label: Text(_getStatusText(status)),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? status : '';
                        });
                        _loadProjects();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // 项目列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _projects.isEmpty
                    ? const Center(
                        child: Text('暂无项目'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProjects,
                        child: ListView.builder(
                          itemCount: _projects.length,
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

  Widget _buildProjectCard(Project project) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    ),
                  ),
                ),
                _buildStatusChip(project.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(project.type, Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip(project.field, Colors.green),
                const SizedBox(width: 8),
                _buildInfoChip(project.stage, Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '进度：${project.progressCount ?? 0} 次',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Text(
                  '意向：${project.intentsCount ?? 0} 个',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '更新时间：${_formatDate(project.updatedAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailScreen(projectId: project.id),
                        ),
                      ).then((_) => _loadProjects());
                    },
                    child: const Text('查看详情'),
                  ),
                ),
                const SizedBox(width: 8),
                if (project.status == 'active')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddProgressScreen(projectId: project.id),
                          ),
                        ).then((_) => _loadProjects());
                      },
                      child: const Text('更新进度'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'paused':
        color = Colors.orange;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case '全部':
        return '全部';
      case 'active':
        return '进行中';
      case 'paused':
        return '暂停';
      case 'closed':
        return '已关闭';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
