import 'dart:convert';
import 'package:http/http.dart' as http;
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
  // 使用实际IP地址，确保Android模拟器可以连接
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.3:3000', // 使用主机实际IP地址
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

    final uri = Uri.parse('$baseUrl/projects').replace(queryParameters: queryParams);
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
    
    if (response.statusCode == 200) return Project.fromJson(jsonDecode(response.body));
    _throwFor(response);
  }

  Future<Map<String, dynamic>> createProject({
    required String title,
    required String type,
    required String field,
    required String stage,
    String? blocker,
    String? helpType,
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
        'is_public_progress': isPublicProgress,
      }),
    );
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    _throwFor(response);
  }

  Future<Map<String, dynamic>> updateProjectStatus(int id, String status) async {
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
      headers: _headers,
    );
    
    if (response.statusCode == 200) return;
    _throwFor(response);
  }

  // 进度相关
  Future<Map<String, dynamic>> addProgress(int projectId, String content, {String? summary}) async {
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
  Future<Map<String, dynamic>> submitIntent(int projectId, {
    required String offer,
    required String expect,
    required String contact,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/intents/$projectId'),
      headers: _headers,
      body: jsonEncode({
        'offer': offer,
        'expect': expect,
        'contact': contact,
      }),
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

  Future<void> updateIntentStatus(int projectId, int intentId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/intents/$projectId/$intentId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    
    if (response.statusCode == 200) return;
    _throwFor(response);
  }

  // 个人中心相关
  Future<List<Project>> getMyProjects({String? status, int page = 1, int limit = 20}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/me/projects').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Project.fromJson(json)).toList();
    }
    _throwFor(response);
  }

  Future<List<Intent>> getMyIntents({String? status, int page = 1, int limit = 20}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/me/intents').replace(queryParameters: queryParams);
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
    
    if (response.statusCode == 200) return User.fromJson(jsonDecode(response.body));
    _throwFor(response);
  }

  Future<Map<String, dynamic>> updateProfile({String? nickname, List<String>? skills}) async {
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
}
