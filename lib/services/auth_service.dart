import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user.dart';
import '../models/project.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _initialized = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    debugPrint('AuthService: init started');
    await _loadToken();
    debugPrint('AuthService: token loaded = ${_apiService.token != null}');
    if (_apiService.token != null) {
      try {
        debugPrint('AuthService: calling getProfile...');
        _currentUser = await _apiService.getProfile();
        debugPrint('AuthService: getProfile success, user = ${_currentUser?.email}');
      } catch (e) {
        debugPrint('AuthService: getProfile failed: $e');
        await logout();
      }
    } else {
      debugPrint('AuthService: no token found, staying logged out');
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _apiService.setToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    debugPrint('AuthService: saving token to prefs');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    debugPrint('AuthService: token saved');
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    return await _apiService.sendVerificationCode(email);
  }

  Future<Map<String, dynamic>> loginWithCode(String email, String code) async {
    debugPrint('AuthService: loginWithCode called');
    final result = await _apiService.loginWithCode(email, code);
    debugPrint('AuthService: loginWithCode success, token = ${result['token'].substring(0, 10)}...');
    
    await _saveToken(result['token']);
    
    // 重新获取完整的用户信息（包含头像）
    try {
      _currentUser = await _apiService.getProfile();
      debugPrint('AuthService: getProfile success, user = ${_currentUser?.email}');
    } catch (e) {
      debugPrint('AuthService: getProfile failed, using login user data: $e');
      _currentUser = User.fromJson(result['user']);
    }
    
    debugPrint('AuthService: currentUser set = ${_currentUser?.email}');
    notifyListeners();
    
    return result;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _apiService.clearToken();
    _currentUser = null;
    notifyListeners();
  }

  bool isAuthExpiredError(Object e) {
    if (e is ApiException) {
      return e.statusCode == 401 || e.statusCode == 403;
    }
    return false;
  }

  ApiService get apiService => _apiService;
  
  // 添加缺失的方法
  Future<List<Project>> getMyProjects({String? status, int page = 1, int limit = 20}) async {
    return await _apiService.getMyProjects(status: status, page: page, limit: limit);
  }

  // 刷新用户信息
  Future<void> refreshUser() async {
    if (_apiService.token != null) {
      try {
        _currentUser = await _apiService.getProfile();
        notifyListeners();
      } catch (e) {
        debugPrint('RefreshUser failed: $e');
      }
    }
  }

  void updateAvatarUrl(String avatarUrl) {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = User(
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      skills: List<String>.from(user.skills),
      createdAt: user.createdAt,
      avatarUrl: avatarUrl,
      bio: user.bio,
    );
    notifyListeners();
  }
}
