import 'package:app/providers/bluetooth_provider.dart';
import 'package:app/providers/coaching_provider.dart';
import 'package:app/screens/main_holder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'providers/squat_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterBluePlus.setLogLevel(LogLevel.none, color: false); // 블루투스 관련 로그 뜨지 않게
  await dotenv.load(fileName: ".env"); // .env 파일 읽도록

  // ✏️ 앱 시작 시 OS 상단바를 완전 투명 및 검은색 아이콘으로 고정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    // 앱 전체에서 provider들을 이용할 수 있도록 주입
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SquatProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => CoachingProvider()),
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
      theme: AppTheme.darkTheme,
      home: const MainHolder(),
    );
  }
}