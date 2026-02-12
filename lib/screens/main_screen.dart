import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'publish_entry_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final ValueNotifier<int> _homeRefreshNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _profileRefreshNotifier = ValueNotifier<int>(0);
  DateTime? _lastBackPressTime;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePageWrapper(refreshListenable: _homeRefreshNotifier),
      ProfilePageWrapper(refreshListenable: _profileRefreshNotifier),
    ];
  }

  @override
  void dispose() {
    _homeRefreshNotifier.dispose();
    _profileRefreshNotifier.dispose();
    super.dispose();
  }

  Future<bool> _handleWillPop() async {
    final now = DateTime.now();
    
    if (_lastBackPressTime == null || 
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再按一次退出'),
          duration: Duration(seconds: 2),
        ),
      );
      
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.divider)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: '',
                    index: 0,
                  ),
                  _buildPublishButton(),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: '',
                    index: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublishButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PublishEntryScreen()),
        );
        _homeRefreshNotifier.value += 1;
        _profileRefreshNotifier.value += 1;
      },
      child: Container(
        width: 42,
        height: 34,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          _profileRefreshNotifier.value += 1;
        }
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.grey[700] : AppTheme.textSecondary,
              size: label.isEmpty ? 32 : 24,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.grey[700] : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomePageWrapper extends StatelessWidget {
  final ValueListenable<int>? refreshListenable;

  const HomePageWrapper({super.key, this.refreshListenable});

  @override
  Widget build(BuildContext context) {
    return ModernHomeScreen(refreshListenable: refreshListenable);
  }
}

class ProfilePageWrapper extends StatelessWidget {
  final ValueListenable<int>? refreshListenable;

  const ProfilePageWrapper({super.key, this.refreshListenable});

  @override
  Widget build(BuildContext context) {
    return ModernProfileScreen(refreshListenable: refreshListenable);
  }
}
