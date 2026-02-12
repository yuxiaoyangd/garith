import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../models/intent.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  // API基础URL配置 - 安卓真机使用局域网IP
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.garith.jianjiemaa.com', // 生产API域名
  );
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  String? get token => _token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Map<String, String> get _authHeaders => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is String && err.isNotEmpty) return err;
      }
    } catch (_) {
      // ignore
    }
    return 'Request failed (${response.statusCode})';
  }

  Never _throwFor(http.Response response) {
    throw ApiException(response.statusCode, _errorMessage(response));
  }

  // 认证相关
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-code'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    _throwFor(response);
  }

  Future<Map<String, dynamic>> loginWithCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['token']);
      return data;
    }
    _throwFor(response);
  }

  // 项目相关
  Future<List<Project>> getProjects({
    String? field,
    String? type,
    String? stage,
    String? category,
    String? search,
    String status = 'active',
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'status': status,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (field != null) queryParams['field'] = field;
    if (type != null) queryParams['type'] = type;
    if (stage != null) queryParams['stage'] = stage;
    if (category != null) queryParams['category'] = category;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse(
      '$baseUrl/projects',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Project.fromJson(json)).toList();
    }
    _throwFor(response);
  }

  Future<Project> getProjectById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/projects/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200)
      return Project.fromJson(jsonDecode(response.body));
    _throwFor(response);
  }

  Future<Map<String, dynamic>> createProject({
    required String title,
    required String type,
    required String field,
    required String stage,
    String? blocker,
    String? helpType,
    List<String>? images,
    bool isPublicProgress = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'type': type,
        'field': field,
        'stage': stage,
        if (blocker != null) 'blocker': blocker,
        if (helpType != null) 'help_type': helpType,
        if (images != null && images.isNotEmpty) 'images': images,
        'is_public_progress': isPublicProgress,
      }),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    _throwFor(response);
  }

  Future<Map<String, dynamic>> updateProject(
    int id, {
    String? title,
    String? type,
    String? field,
    String? stage,
    String? blocker,
    String? helpType,
    List<String>? images,
    bool? isPublicProgress,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (type != null) body['type'] = type;
    if (field != null) body['field'] = field;
    if (stage != null) body['stage'] = stage;
    if (blocker != null) body['blocker'] = blocker;
    if (helpType != null) body['helpType'] = helpType;
    if (images != null) body['images'] = images;
    if (isPublicProgress != null) body['isPublicProgress'] = isPublicProgress;

    final response = await http.patch(
      Uri.parse('$baseUrl/projects/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    _throwFor(response);
  }

  Future<Map<String, dynamic>> updateProjectStatus(
    int id,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/projects/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    _throwFor(response);
  }

  Future<void> deleteProject(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/projects/$id'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) return;
    _throwFor(response);
  }

  // 进度相关
  Future<Map<String, dynamic>> addProgress(
    int projectId,
    String content, {
    String? summary,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/progress/$projectId'),
      headers: _headers,
      body: jsonEncode({
        'content': content,
        if (summary != null) 'summary': summary,
      }),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    _throwFor(response);
  }

  // 合作意向相关
  Future<Map<String, dynamic>> submitIntent(
    int projectId, {
    required String offer,
    required String expect,
    required String contact,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/intents/$projectId'),
      headers: _headers,
      body: jsonEncode({'offer': offer, 'expect': expect, 'contact': contact}),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    _throwFor(response);
  }

  Future<List<Intent>> getProjectIntents(int projectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/intents/$projectId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Intent.fromJson(json)).toList();
    }
    _throwFor(response);
  }

  Future<bool> checkUserIntent(int projectId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/intents/$projectId/check'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasIntent'] ?? false;
    }
    _throwFor(response);
  }

  Future<void> updateIntentStatus(
    int projectId,
    int intentId,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/intents/$projectId/$intentId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) return;
    _throwFor(response);
  }

  // 个人中心相关
  Future<List<Project>> getMyProjects({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/me/projects',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Project.fromJson(json)).toList();
    }
    _throwFor(response);
  }

  Future<List<Intent>> getMyIntents({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/me/intents',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Intent.fromJson(json)).toList();
    }
    _throwFor(response);
  }

  Future<List<Intent>> getReceivedIntents({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/me/received-intents',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Intent.fromJson(json)).toList();
    }
    _throwFor(response);
  }

  Future<User> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200)
      return User.fromJson(jsonDecode(response.body));
    _throwFor(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? nickname,
    List<String>? skills,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/me/profile'),
      headers: _headers,
      body: jsonEncode({
        if (nickname != null) 'nickname': nickname,
        if (skills != null) 'skills': skills,
      }),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    _throwFor(response);
  }

  // 通知相关API
  Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'unread_only': unreadOnly.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/notifications',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    _throwFor(response);
  }

  Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    _throwFor(response);
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: '{}',
    );

    if (response.statusCode != 200) {
      _throwFor(response);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: '{}',
    );

    if (response.statusCode != 200) {
      _throwFor(response);
    }
  }

  // 用户管理相关API
  Future<Map<String, dynamic>> getUserProfileNew() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    _throwFor(response);
  }

  Future<void> updateUserProfileNew({
    String? nickname,
    String? bio,
    List<String>? skills,
  }) async {
    final Map<String, dynamic> body = {};
    if (nickname != null) body['nickname'] = nickname;
    if (bio != null) body['bio'] = bio;
    if (skills != null) body['skills'] = skills;

    final response = await http.patch(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      _throwFor(response);
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    _throwFor(response);
  }

  // 上传头像
  Future<String> uploadAvatar(String imagePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/avatar'),
    );

    // 添加认证头
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // 添加文件（显式设置contentType，避免部分Android机型上传为application/octet-stream）
    final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
    final parts = mimeType.split('/');
    final mediaType = parts.length == 2
        ? MediaType(parts[0], parts[1])
        : MediaType('image', 'jpeg');
    request.files.add(
      await http.MultipartFile.fromPath(
        'avatar',
        imagePath,
        contentType: mediaType,
      ),
    );

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['avatar_url'];
    } else {
      final error = jsonDecode(responseBody);
      throw ApiException(
        response.statusCode,
        error['error'] ?? 'Upload failed',
      );
    }
  }

  // 上传项目图片
  Future<List<String>> uploadProjectImages(List<String> imagePaths) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/project-images'),
    );

    // 添加认证头
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // 添加文件（显式设置contentType）
    for (int i = 0; i < imagePaths.length; i++) {
      final path = imagePaths[i];
      final mimeType = lookupMimeType(path) ?? 'image/jpeg';
      final parts = mimeType.split('/');
      final mediaType = parts.length == 2
          ? MediaType(parts[0], parts[1])
          : MediaType('image', 'jpeg');
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          path,
          contentType: mediaType,
        ),
      );
    }

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return List<String>.from(data['images']);
    } else {
      final error = jsonDecode(responseBody);
      throw ApiException(
        response.statusCode,
        error['error'] ?? 'Upload failed',
      );
    }
  }
}
