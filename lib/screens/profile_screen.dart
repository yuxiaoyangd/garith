import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'my_projects_screen.dart';
import 'my_intents_screen.dart';

class ModernProfileScreen extends StatefulWidget {
  const ModernProfileScreen({super.key});

  @override
  State<ModernProfileScreen> createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends State<ModernProfileScreen> {
  bool _uploadingAvatar = false;
  String? _localAvatarUrl;
  int _avatarCacheBuster = 0;

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      setState(() => _uploadingAvatar = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final avatarUrl = await authService.apiService.uploadAvatar(image.path);
        authService.updateAvatarUrl(avatarUrl);
        
        // 更新用户信息
        await authService.refreshUser();

        if (mounted) {
          setState(() {
            _localAvatarUrl = avatarUrl;
            _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('头像上传成功'),
              backgroundColor: AppTheme.accent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('头像上传失败: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _uploadingAvatar = false);
        }
      }
    }
  }

  String? _buildAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    final resolved = avatarUrl.startsWith('http')
        ? avatarUrl
        : avatarUrl.startsWith('/')
            ? '${ApiService.baseUrl}$avatarUrl'
            : '${ApiService.baseUrl}/$avatarUrl';
    if (_avatarCacheBuster == 0) return resolved;

    final separator = resolved.contains('?') ? '&' : '?';
    return '$resolved$separator$_avatarCacheBuster';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final rawAvatarUrl = _localAvatarUrl ?? user?.avatarUrl;
    final displayAvatarUrl = _buildAvatarUrl(rawAvatarUrl);

    return Scaffold(
      backgroundColor: Colors.white, // 纯白背景更现代
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '个人中心', 
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. 头像与基本信息
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200, width: 4),
                          ),
                          child: ClipOval(
                            child: displayAvatarUrl != null
                                ? Image.network(
                                    displayAvatarUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: const Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 48,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 48,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (_uploadingAvatar)
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        if (!_uploadingAvatar)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.nickname ?? '未登录用户',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 2. 数据概览 (可选，增强社区感)
            FutureBuilder<Map<String, dynamic>>(
              future: Provider.of<AuthService>(context, listen: false).apiService.getUserStats(),
              builder: (context, snapshot) {
                final stats = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('项目', stats?['projects']?.toString() ?? '0'),
                      _buildVerticalDivider(),
                      _buildStatItem('意向', stats?['intents']?.toString() ?? '0'),
                      _buildVerticalDivider(),
                      _buildStatItem('合作', stats?['collaborations']?.toString() ?? '0'),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // 3. 菜单列表 (分组风格)
            _buildMenuSection(context, [
              _MenuItem(
                icon: Icons.folder_outlined,
                title: '我的发布',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProjectsScreen())),
              ),
              _MenuItem(
                icon: Icons.mail_outline,
                title: '合作意向',
                badgeCount: 0, // 真实数据，暂时为0
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyIntentsScreen())),
              ),
            ]),

            const SizedBox(height: 20),

            _buildMenuSection(context, [
              _MenuItem(
                icon: Icons.help_outline,
                title: '帮助与反馈',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.logout,
                title: '退出登录',
                isDestructive: true,
                onTap: () {
                  _showLogoutDialog(context, authService);
                },
              ),
            ]),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 20, width: 1, color: Colors.grey.shade300);
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA), // 非常淡的背景区分
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) {
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon, 
                color: item.isDestructive ? AppTheme.error : AppTheme.primary, 
                size: 20
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: item.isDestructive ? AppTheme.error : AppTheme.textPrimary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
            onTap: item.onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final int badgeCount;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.badgeCount = 0,
  });
}
