import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'providers/squat_provider.dart';

void main() {
  runApp(
    // 앱 전체에서 SquatProvider를 사용할 수 있게 등록
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SquatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthCare App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const LoginScreen(), // 로그인 페이지로
    );
  }
}