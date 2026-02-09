import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/project.dart';
import '../screens/submit_intent_screen.dart';

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
      setState(() => _project = project);
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
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目详情'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _project == null
              ? const Center(child: Text('项目不存在'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProjectInfo(),
                      const SizedBox(height: 24),
                      if (_project!.progress.isNotEmpty) _buildProgressSection(),
                      const SizedBox(height: 24),
                      if (authService.isLoggedIn && 
                          _project!.ownerId != authService.currentUser!.id &&
                          _project!.status == 'active')
                        _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProjectInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _project!.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(_project!.type, Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip(_project!.field, Colors.green),
                const SizedBox(width: 8),
                _buildInfoChip(_project!.stage, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusChip(_project!.status),
            const SizedBox(height: 16),
            if (_project!.blocker != null) ...[
              const Text(
                '当前卡点',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_project!.blocker!),
              const SizedBox(height: 16),
            ],
            if (_project!.helpType != null) ...[
              const Text(
                '希望获得的帮助',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_project!.helpType!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text('创建者：${_project!.ownerNickname}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text('创建时间：${_formatDate(_project!.createdAt)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.update, size: 16),
                const SizedBox(width: 4),
                Text('更新时间：${_formatDate(_project!.updatedAt)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '项目进度',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._project!.progress.map((progress) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(progress.createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(progress.content),
                if (progress.summary != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '小结：${progress.summary}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmitIntentScreen(projectId: _project!.id),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('提交合作意向'),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'active':
        color = Colors.green;
        text = '进行中';
        break;
      case 'paused':
        color = Colors.orange;
        text = '暂停';
        break;
      case 'closed':
        color = Colors.grey;
        text = '已关闭';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
