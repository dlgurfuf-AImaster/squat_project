import 'package:app/providers/bluetooth_provider.dart';
import 'package:app/screens/main_holder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'providers/squat_provider.dart';

void main() {
  runApp(
    // 앱 전체에서 provider들을 이용할 수 있도록 주입
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SquatProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
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
      home: const MainHolder(), //TODO 임시로 로그인 페이지 무시하고 일단 들어감
    );
  }
}