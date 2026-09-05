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

  // 화면 전체를 시스템 영역까지 확장 (Edge-to-Edge)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
    // AnnotatedRegion으로 MaterialApp 전체를 감싸서 렌더링 시점에도 시스템 UI 스타일을 강제 고정
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent, // 하단 제스처 바 투명화
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark, // 제스처 바 어둡게 설정
        systemNavigationBarContrastEnforced: false,
        statusBarColor: Colors.transparent, // 상단 상태바 투명화
        statusBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'SquatMate',
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}