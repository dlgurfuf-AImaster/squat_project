import 'package:app/providers/bluetooth_provider.dart';
import 'package:app/providers/coaching_provider.dart';
import 'package:app/providers/squat_provider.dart';
import 'package:app/providers/user_provider.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/screens/main_holder.dart';
import 'package:app/services/api_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding =
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(
    widgetsBinding: widgetsBinding,
  );

  FlutterBluePlus.setLogLevel(
    LogLevel.none,
    color: false,
  );

  await dotenv.load(fileName: ".env");

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  final userProvider = UserProvider();

  // 자동 로그인
  final savedUser = await ApiService().restoreLogin();

  if (savedUser != null) {
    userProvider.setUser(savedUser);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: userProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => SquatProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BluetoothProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CoachingProvider(),
        ),
      ],
      child: MyApp(
        isLoggedIn: savedUser != null,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 첫 Flutter 화면이 렌더링된 후 네이티브 스플래시 제거
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'SquatMate',
        theme: AppTheme.darkTheme,

        home: widget.isLoggedIn
            ? const MainHolder()
            : const LoginScreen(),
      ),
    );
  }
}