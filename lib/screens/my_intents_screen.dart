import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/intent.dart' as models;
import '../theme.dart';
import 'intent_detail_screen.dart';

class MyIntentsScreen extends StatefulWidget {
  final int? projectId; // 指定项目ID，用于查看特定项目的意向
  final bool isProjectOwnerView; // 是否作为项目所有者查看收到的意向
  final String? projectTitle;

  const MyIntentsScreen({
    super.key,
    this.projectId,
    this.isProjectOwnerView = false,
    this.projectTitle,
  });

  @override
  State<MyIntentsScreen> createState() => _MyIntentsScreenState();
}

class _MyIntentsScreenState extends State<MyIntentsScreen>
    with SingleTickerProviderStateMixin {
  List<models.Intent> _sentIntents = [];
  List<models.Intent> _receivedIntents = [];
  bool _loading = true;
  late TabController _tabController;

  String? _projectTitle;

  @override
  void initState() {
    super.initState();
    _projectTitle = widget.projectTitle;
    _tabController = TabController(length: 2, vsync: this);
    _loadIntents();
    _loadProjectTitleIfNeeded();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectTitleIfNeeded() async {
    if (!widget.isProjectOwnerView || widget.projectId == null) return;
    if (_projectTitle != null && _projectTitle!.trim().isNotEmpty) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final project = await authService.apiService.getProjectById(
        widget.projectId!,
      );
      if (!mounted) return;
      setState(() => _projectTitle = project.title);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadIntents() async {
    setState(() => _loading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (widget.projectId != null) {
        // 特定项目模式
        if (widget.isProjectOwnerView) {
          _receivedIntents = await authService.apiService.getProjectIntents(
            widget.projectId!,
          );
        } else {
          // 理论上不会走到这里，除非查看"我对此项目的意向"
          // 这里简单复用 getMyIntents，虽然它返回所有意向，但我们可以过滤（如果需要）
          // 或者保持原样
          _sentIntents = await authService.apiService.getMyIntents();
          // 可以在这里过滤 projectId == widget.projectId
          _sentIntents = _sentIntents
              .where((i) => i.projectId == widget.projectId)
              .toList();
        }
      } else {
        // 通用模式（个人中心入口），加载两类数据
        final sentFuture = authService.apiService.getMyIntents();
        final receivedFuture = authService.apiService.getReceivedIntents();

        final results = await Future.wait([sentFuture, receivedFuture]);
        _sentIntents = results[0];
        _receivedIntents = results[1];
      }

      if (!mounted) return;
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
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果指定了 projectId，只显示对应的列表，不显示 Tab
    if (widget.projectId != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(widget.isProjectOwnerView ? '收到的意向' : '我的意向'),
          elevation: 0,
          backgroundColor: AppTheme.surface,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildList(
                widget.isProjectOwnerView ? _receivedIntents : _sentIntents,
                isReceived: widget.isProjectOwnerView,
              ),
      );
    }

    // 通用模式，显示 Tab
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('合作意向'),
        elevation: 0,
        backgroundColor: AppTheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppTheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _tabController.animateTo(0),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final isSelected = _tabController.index == 0;
                          return Text(
                            '我收到的',
                            style: TextStyle(
                              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _tabController.animateTo(1),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final isSelected = _tabController.index == 1;
                          return Text(
                            '我发起的',
                            style: TextStyle(
                              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_receivedIntents, isReceived: true),
                _buildList(_sentIntents, isReceived: false),
              ],
            ),
    );
  }

  Widget _buildList(List<models.Intent> intents, {required bool isReceived}) {
    if (intents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isReceived ? Icons.inbox_outlined : Icons.send_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isReceived ? '暂无收到的意向' : '暂无发起的意向',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: intents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final intent = intents[index];
        return isReceived
            ? _buildReceivedIntentCard(intent)
            : _buildSentIntentCard(intent);
      },
    );
  }

  // 发起的意向卡片
  Widget _buildSentIntentCard(models.Intent intent) {
    final projectTitle = _resolveProjectTitle(intent);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // side: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(intent, projectTitle),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '提交于 ${_formatDate(intent.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusText(intent.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 收到的意向卡片
  Widget _buildReceivedIntentCard(models.Intent intent) {
    final projectTitle = _resolveProjectTitle(intent);
    final userNickname = intent.userNickname ?? '未知用户';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // side: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(intent, projectTitle),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_received_rounded,
                      size: 16,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userNickname,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '申请参与: $projectTitle',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusText(intent.status),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(intent.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
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
    );
  }

  void _navigateToDetail(models.Intent intent, String projectTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntentDetailScreen(
          intent: {
            'id': intent.id,
            'project_id': intent.projectId,
            'project_owner_id': intent.projectOwnerId,
            'user_id': intent.userId,
            'nickname': intent.userNickname,
            'email': intent.userEmail,
            'offer': intent.offer,
            'expect': intent.expect,
            'contact': intent.contact,
            'status': intent.status,
            'created_at': intent.createdAt,
          },
          projectTitle: projectTitle,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadIntents();
      }
    });
  }

  Widget _buildStatusText(String status) {
    // 待处理状态不显示
    if (status == 'submitted') {
      return const SizedBox.shrink();
    }

    Color color;
    String text;
    switch (status) {
      case 'viewed': // 对应 "已接受" 或 "已读"
        color = AppTheme.primary;
        text = '已联系';
        break;
      case 'closed':
        color = AppTheme.textSecondary;
        text = '已关闭';
        break;
      default:
        color = AppTheme.textSecondary;
        text = status;
    }

    return Text(
      text,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  String _resolveProjectTitle(models.Intent intent) {
    final intentTitle = (intent.projectTitle ?? '').trim();
    if (intentTitle.isNotEmpty) return intentTitle;
    final ownerTitle = (_projectTitle ?? '').trim();
    if (ownerTitle.isNotEmpty) return ownerTitle;
    return '未知项目';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
