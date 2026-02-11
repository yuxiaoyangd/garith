import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/project.dart';
import '../screens/submit_intent_screen.dart';
import '../screens/add_progress_simple_screen.dart';
import '../screens/edit_project_screen.dart';
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
  bool _hasSubmittedIntent = false;

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

      // 检查用户是否已提交意向
      if (authService.isLoggedIn && project.ownerId != authService.currentUser!.id) {
        final hasIntent = await authService.apiService.checkUserIntent(widget.projectId);
        if (!mounted) return;
        setState(() => _hasSubmittedIntent = hasIntent);
      }
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('项目详情'),
        actions: [
          if (_project != null &&
              authService.isLoggedIn &&
              _project!.ownerId == authService.currentUser!.id)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 22,
                color: AppTheme.textPrimary.withValues(alpha: 0.7),
              ),
              tooltip: '编辑项目',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProjectScreen(project: _project!),
                  ),
                ).then((result) {
                  if (result == true) _loadProject();
                });
              },
            ),
          const SizedBox(width: 4),
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
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        if (_project!.images.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildImageGallery(),
                        ],
                        const SizedBox(height: 28),
                        _buildInfoGrid(),
                        const SizedBox(height: 28),
                        if (_project!.blocker != null) ...[
                          _buildSectionTitle('项目描述'),
                          const SizedBox(height: 16),
                          _buildContentCard(_project!.blocker!),
                          const SizedBox(height: 28),
                        ],
                        if (_project!.helpType != null) ...[
                          _buildSectionTitle('需求描述'),
                          const SizedBox(height: 16),
                          _buildContentCard(_project!.helpType!),
                          const SizedBox(height: 28),
                        ],
                        _buildSectionTitle('项目进度'),
                        const SizedBox(height: 16),
                        if (_project!.progress.isEmpty)
                          _buildEmptyProgress(authService)
                        else ...[
                          _buildProgressTimeline(),
                          const SizedBox(height: 20),
                          if (authService.isLoggedIn && 
                              _project!.ownerId == authService.currentUser!.id)
                            _buildAddProgressButton(),
                        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Text(
          '你是该项目的创建者',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      );
    }

    // 如果未登录或非所有者，且项目活跃，显示合作按钮
    if (_project!.status == 'active') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _hasSubmittedIntent ? null : () {
              if (!authService.isLoggedIn) {
                _showError('请先登录');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubmitIntentScreen(projectId: _project!.id),
                ),
              ).then((result) {
                if (result == true) {
                  setState(() => _hasSubmittedIntent = true);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasSubmittedIntent 
                  ? AppTheme.textSecondary.withValues(alpha: 0.08)
                  : AppTheme.accent,
              foregroundColor: _hasSubmittedIntent 
                  ? AppTheme.textSecondary
                  : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppTheme.textSecondary.withValues(alpha: 0.08),
            ),
            child: Text(
              _hasSubmittedIntent ? '已发合作意向' : '我有意向合作',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
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
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _project!.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            height: 1.3,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _project!.ownerNickname.isNotEmpty 
                      ? _project!.ownerNickname[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _project!.ownerNickname,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    final images = _project!.images;
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final imageUrl = _resolveImageUrl(images[index]);
          return GestureDetector(
            onTap: () => _viewImage(imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.divider.withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.divider.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildInfoItem('领域', _project!.field)),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.divider.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(child: _buildInfoItem('类型', _project!.type)),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.divider.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(child: _buildInfoItem('阶段', _project!.stage)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildContentCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.divider.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 15,
          color: AppTheme.textPrimary,
          height: 1.7,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _buildEmptyProgress(AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.divider.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 40,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无进度更新',
            style: TextStyle(
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          if (authService.isLoggedIn && 
              _project!.ownerId == authService.currentUser!.id) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProgressSimpleScreen(
                      projectId: _project!.id,
                    ),
                  ),
                ).then((result) {
                  if (result == true) _loadProject();
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                '新增进度记录',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surface,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.divider.withValues(alpha: 0.5),
                              AppTheme.divider.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(progress.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.divider.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progress.content,
                              style: const TextStyle(
                                height: 1.6,
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.1,
                              ),
                            ),
                            if (progress.summary != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accent.withValues(alpha: 0.1),
                                    width: 0.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accent.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '小结',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.accent,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      progress.summary!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textPrimary,
                                        height: 1.6,
                                        letterSpacing: 0.1,
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

  Widget _buildAddProgressButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProgressSimpleScreen(
                projectId: _project!.id,
              ),
            ),
          ).then((result) {
            if (result == true) _loadProject();
          });
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          '新增进度记录',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.accent,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _resolveImageUrl(String value) {
    if (value.startsWith('http')) return value;
    if (value.startsWith('/')) return '${ApiService.baseUrl}$value';
    return '${ApiService.baseUrl}/$value';
  }
}