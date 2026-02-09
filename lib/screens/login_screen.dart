import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_loading) return;
    if (_emailController.text.isEmpty) {
      _showError('请输入邮箱');
      return;
    }

    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendVerificationCode(_emailController.text);
      setState(() => _codeSent = true);
      _showSuccess('验证码已发送');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    if (_loading) return;
    if (_codeController.text.isEmpty) {
      _showError('请输入验证码');
      return;
    }

    setState(() => _loading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.loginWithCode(_emailController.text, _codeController.text);
      _showSuccess('登录成功');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.business_center,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Garith',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '需求协作平台',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            if (_codeSent) ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '验证码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sms),
                ),
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _loading ? null : (_codeSent ? _login : _sendCode),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(_codeSent ? '登录' : '发送验证码'),
            ),
            if (_codeSent) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : _sendCode,
                child: const Text('重新发送验证码'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
