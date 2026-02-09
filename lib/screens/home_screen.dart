import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/project.dart';
import '../screens/project_detail_screen.dart';
import '../screens/create_project_screen.dart';
import '../screens/my_projects_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> _projects = [];
  bool _loading = true;
  String _selectedField = '';
  String _selectedType = '';
  String _selectedStage = '';

  final List<String> _fields = ['全部', 'Web', 'IoT', 'AI', '移动开发', '其他'];
  final List<String> _types = ['全部', '需求', '合伙', '外包'];
  final List<String> _stages = ['全部', '想法', '原型', '开发中', '已上线'];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final projects = await authService.apiService.getProjects(
        field: _selectedField.isEmpty || _selectedField == '全部' ? null : _selectedField,
        type: _selectedType.isEmpty || _selectedType == '全部' ? null : _selectedType,
        stage: _selectedStage.isEmpty || _selectedStage == '全部' ? null : _selectedStage,
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
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garith'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyProjectsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authService.logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('退出登录'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选器
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('筛选条件', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('领域', _fields, _selectedField, (value) {
                      setState(() => _selectedField = value);
                      _loadProjects();
                    }),
                    _buildFilterChip('类型', _types, _selectedType, (value) {
                      setState(() => _selectedType = value);
                      _loadProjects();
                    }),
                    _buildFilterChip('阶段', _stages, _selectedStage, (value) {
                      setState(() => _selectedStage = value);
                      _loadProjects();
                    }),
                  ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
          ).then((_) => _loadProjects());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, List<String> options, String selected, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: options.map((option) {
            final isSelected = selected == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option);
                } else {
                  onChanged('');
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          ).then((_) => _loadProjects());
        },
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
              if (project.blocker != null) ...[
                const SizedBox(height: 8),
                Text(
                  '卡点：${project.blocker}',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '创建者：${project.ownerNickname}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    '${project.updatedAt.month}月${project.updatedAt.day}日更新',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
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
        status == 'active' ? '进行中' : status == 'paused' ? '暂停' : '已关闭',
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
}
