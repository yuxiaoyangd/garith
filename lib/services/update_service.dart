import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String? versionName;
  final int? buildNumber;
  final bool force;
  final String title;
  final String message;
  final String? url;

  const UpdateInfo({
    required this.versionName,
    required this.buildNumber,
    required this.force,
    required this.title,
    required this.message,
    required this.url,
  });

  static UpdateInfo? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is num) {
      return UpdateInfo(
        versionName: null,
        buildNumber: json.toInt(),
        force: false,
        title: '发现新版本',
        message: '请更新到最新版本以获得更好的体验。',
        url: null,
      );
    }
    if (json is String) {
      final buildNumber = int.tryParse(json.trim());
      return UpdateInfo(
        versionName: buildNumber == null ? json.trim() : null,
        buildNumber: buildNumber,
        force: false,
        title: '发现新版本',
        message: '请更新到最新版本以获得更好的体验。',
        url: null,
      );
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      final versionName = _firstNonEmptyString(map, [
        'version',
        'version_name',
        'versionName',
        'latest_version',
        'latestVersion',
      ]);
      final buildNumber = _firstInt(map, [
        'build',
        'build_number',
        'buildNumber',
        'version_code',
        'versionCode',
      ]);
      final force = _firstBool(map, [
        'force',
        'force_update',
        'forceUpdate',
        'mandatory',
        'is_force',
        'isForce',
      ]);
      final title = _firstNonEmptyString(map, ['title', 'name']) ?? '发现新版本';
      final message = _firstNonEmptyString(map, ['message', 'content', 'desc', 'description']) ??
          '请更新到最新版本以获得更好的体验。';
      final url = _firstNonEmptyString(map, [
        'url',
        'download_url',
        'downloadUrl',
        'link',
        'apk',
      ]);
      return UpdateInfo(
        versionName: versionName,
        buildNumber: buildNumber,
        force: force,
        title: title,
        message: message,
        url: url,
      );
    }
    return null;
  }

  static String? _firstNonEmptyString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int? _firstInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool _firstBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is bool) return value;
      final text = value.toString().toLowerCase();
      if (text == '1' || text == 'true' || text == 'yes') return true;
      if (text == '0' || text == 'false' || text == 'no') return false;
    }
    return false;
  }
}

class UpdateCheckResult {
  final UpdateInfo info;
  final String currentVersion;
  final String latestVersion;

  const UpdateCheckResult({
    required this.info,
    required this.currentVersion,
    required this.latestVersion,
  });
}

class UpdateService {
  static const String updateJsonUrl = 'https://garith.jianjiemaa.com/public/update.json';

  Future<UpdateCheckResult?> checkForUpdate() async {
    final info = await _fetchUpdateInfo();
    if (info == null) return null;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version.trim();
    final currentBuild = int.tryParse(packageInfo.buildNumber.trim());

    final shouldUpdate = _shouldUpdate(
      info: info,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    );
    if (!shouldUpdate) return null;

    final currentDisplay = currentBuild == null
        ? currentVersion
        : '$currentVersion+$currentBuild';
    final latestDisplay = info.versionName ??
        (info.buildNumber == null ? '未知版本' : 'build ${info.buildNumber}');

    return UpdateCheckResult(
      info: info,
      currentVersion: currentDisplay,
      latestVersion: latestDisplay,
    );
  }

  Future<UpdateInfo?> _fetchUpdateInfo() async {
    try {
      final response = await http.get(Uri.parse(updateJsonUrl));
      if (response.statusCode != 200) return null;
      final body = response.body.trim();
      if (body.isEmpty) return null;
      final json = jsonDecode(body);
      return UpdateInfo.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  bool _shouldUpdate({
    required UpdateInfo info,
    required String currentVersion,
    required int? currentBuild,
  }) {
    if (info.buildNumber != null && currentBuild != null) {
      return info.buildNumber! > currentBuild;
    }
    if (info.versionName != null && info.versionName!.isNotEmpty) {
      return _compareVersions(info.versionName!, currentVersion) > 0;
    }
    return false;
  }

  int _compareVersions(String a, String b) {
    final aParts = _versionParts(a);
    final bParts = _versionParts(b);
    final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < maxLen; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal != bVal) return aVal.compareTo(bVal);
    }
    return 0;
  }

  List<int> _versionParts(String version) {
    final core = version.split(RegExp(r'[+\\-]')).first;
    final parts = core.split('.');
    return parts.map((part) => int.tryParse(part) ?? 0).toList();
  }
}
