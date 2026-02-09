import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user.dart';
import '../models/project.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    await _loadToken();
    if (_apiService.token != null) {
      try {
        _currentUser = await _apiService.getProfile();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _apiService.setToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    return await _apiService.sendVerificationCode(email);
  }

  Future<Map<String, dynamic>> loginWithCode(String email, String code) async {
    final result = await _apiService.loginWithCode(email, code);
    
    await _saveToken(result['token']);
    _currentUser = User.fromJson(result['user']);
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

  ApiService get apiService => _apiService;
  
  // 添加缺失的方法
  Future<List<Project>> getMyProjects({String? status, int page = 1, int limit = 20}) async {
    return await _apiService.getMyProjects(status: status, page: page, limit: limit);
  }
}
