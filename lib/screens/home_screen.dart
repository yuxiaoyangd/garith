import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/project.dart';
import '../widgets/project_card.dart'; 
import '../theme.dart';
import '../constants.dart';
import 'notifications_screen.dart'; 

class ModernHomeScreen extends StatefulWidget {
  final ValueListenable<int>? refreshListenable;

  const ModernHomeScreen({super.key, this.refreshListenable});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final String _allLabel;
  VoidCallback? _refreshListener;
  
  // 筛选状态
  String _selectedField = '全部';
  String _selectedType = '全部';
  String _selectedStage = '全部';
  String _searchQuery = '';
  
  List<Project> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allLabel = '全部';
    if (widget.refreshListenable != null) {
      _refreshListener = () {
        _loadProjects();
      };
      widget.refreshListenable!.addListener(_refreshListener!);
    }
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // 切换Tab时重置筛选并刷新
        _resetFilters();
        _loadProjects();
      }
    });
    _loadProjects();
  }

  @override
  void dispose() {
    if (widget.refreshListenable != null && _refreshListener != null) {
      widget.refreshListenable!.removeListener(_refreshListener!);
    }
    _tabController.dispose();
    super.dispose();
  }

  List<String> _withAll(List<String> items) {
    return [_allLabel, ...items.where((item) => item != _allLabel)];
  }

  void _resetFilters() {
    setState(() {
      _selectedField = '全部';
      _selectedType = '全部';
      _selectedStage = '全部';
    });
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final isProjectTab = _tabController.index == 0;
    final field = _selectedField == _allLabel ? null : _selectedField;
    final type = isProjectTab && _selectedType != _allLabel ? _selectedType : null;
    final stage = isProjectTab && _selectedStage != _allLabel ? _selectedStage : null;
    final category = isProjectTab ? 'project' : 'ability';

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final projects = await authService.apiService.getProjects(
        field: field,
        type: type,
        stage: stage,
        category: category,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      
      if (!mounted) return;
      setState(() => _projects = projects);
    } catch (e) {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isAuthExpiredError(e)) {
        await authService.logout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登录已过期，请重新登录'),
            backgroundColor: AppTheme.error,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载项目失败: ${e.toString()}'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // 更柔和的灰背景
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. 顶部导航栏 (Logo + Tab)
            SliverAppBar(
              title: const Text(
                '亿合 APP',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
              backgroundColor: AppTheme.surface,
              elevation: 0,
              floating: true,
              pinned: true,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: '寻找伙伴'),
                  Tab(text: '发现能力'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.textPrimary),
                  onPressed: () => _showSearchDialog(),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: AppTheme.textPrimary),
                  onPressed: () => _showNotifications(),
                ),
              ],
            ),

            // 2. 筛选栏 (吸顶效果)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverFilterDelegate(
                child: Container(
                  color: AppTheme.surface,
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              _buildFilterChip('领域', _selectedField, _withAll(AppConstants.projectFieldsFlat)),
                              const SizedBox(width: 8),
                              if (_tabController.index == 0) ...[
                                _buildFilterChip('需求类型', _selectedType, _withAll(AppConstants.projectTypes)),
                                const SizedBox(width: 8),
                                _buildFilterChip('阶段', _selectedStage, _withAll(AppConstants.stages)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        // 3. 内容列表
        body: _loading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('加载中...', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              )
            : _projects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        const Text(
                          '暂无项目',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '试试调整筛选条件或发布新项目',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProjects,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _projects.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return ProjectCard(project: _projects[index]);
                      },
                    ),
                  ),
      ),
    );
  }

  // 现代化的筛选胶囊
  Widget _buildFilterChip(String label, String value, List<String> options) {
    bool isActive = value != _allLabel;
    return GestureDetector(
      onTap: () {
        // 弹出底部选择框代替下拉菜单
        _showSelectionSheet(label, options, (val) {
          setState(() {
            if (label == '领域') _selectedField = val;
            else if (label == '需求类型') _selectedType = val;
            else if (label == '阶段') _selectedStage = val;
          });
          _loadProjects();
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label：$value',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppTheme.textSecondary,
          )
        ],
      ),
    );
  }

  
  void _showSelectionSheet(String title, List<String> items, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.8;
        final availableHeight = maxHeight - 120; // 减去标题和padding
        return Container(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  title, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: availableHeight,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item, textAlign: TextAlign.center),
                        onTap: () {
                          onSelected(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        return AlertDialog(
          title: const Text('搜索项目'),
          content: TextField(
            controller: TextEditingController(text: _searchQuery),
            decoration: const InputDecoration(
              hintText: '输入关键词搜索项目...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => tempQuery = value,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _searchQuery = tempQuery);
                Navigator.pop(context);
                _loadProjects();
              },
              child: const Text('搜索'),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}

// 辅助类：用于SliverPersistentHeader
class _SliverFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverFilterDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverFilterDelegate oldDelegate) => oldDelegate.child != child;
}


