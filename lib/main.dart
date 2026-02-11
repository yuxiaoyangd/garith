import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';
import 'widgets/update_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService()..init(),
      child: const GarithApp(),
    ),
  );
}

class GarithApp extends StatelessWidget {
  const GarithApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garith',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: UpdateChecker(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            if (!authService.isInitialized) {
              return const _BootScreen();
            }
            return authService.isLoggedIn ? const MainScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
