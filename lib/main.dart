import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

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
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          return authService.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
