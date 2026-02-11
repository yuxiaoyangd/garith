import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../theme.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;

  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  final UpdateService _updateService = UpdateService();
  bool _checked = false;
  bool _dialogVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate();
    });
  }

  Future<void> _checkUpdate() async {
    final result = await _updateService.checkForUpdate();
    if (!mounted || result == null) return;
    await _showUpdateDialog(result);
  }

  Future<void> _showUpdateDialog(UpdateCheckResult result) async {
    if (_dialogVisible) return;
    _dialogVisible = true;
    final info = result.info;
    await showDialog<void>(
      context: context,
      barrierDismissible: !info.force,
      builder: (context) {
        final dialog = AlertDialog(
          title: Text(info.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info.message),
              const SizedBox(height: 12),
              Text(
                '当前版本：${result.currentVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '最新版本：${result.latestVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (info.force) ...[
                const SizedBox(height: 12),
                Text(
                  '该版本为强制更新，更新后才能继续使用。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
          actions: [
            if (!info.force)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('稍后'),
              ),
            ElevatedButton(
              onPressed: () => _handleUpdate(info),
              child: Text(info.force ? '立即更新' : '更新'),
            ),
          ],
        );

        if (!info.force) return dialog;
        return WillPopScope(
          onWillPop: () async => false,
          child: dialog,
        );
      },
    );
    _dialogVisible = false;
  }

  Future<void> _handleUpdate(UpdateInfo info) async {
    final url = info.url?.trim();
    if (url == null || url.isEmpty) {
      _showSnack('更新链接缺失，请联系管理员');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack('更新链接无效');
      return;
    }
    final ok = await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      _showSnack('无法打开更新链接');
      return;
    }
    if (!info.force && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
