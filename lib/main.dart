import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  await authService.init();
  
  runApp(
    ChangeNotifierProvider.value(
      value: authService,
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          return authService.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
