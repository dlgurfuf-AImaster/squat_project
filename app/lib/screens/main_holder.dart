import 'package:app/screens/arduino_status_screen.dart';
import 'package:app/screens/coaching_screen.dart';
import 'package:app/screens/record_history_screen.dart';
import 'package:app/screens/squat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coaching_provider.dart';

// 탭 바 스크린
class MainHolder extends StatefulWidget {
  const MainHolder({super.key});

  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> {

  final List<Widget> _pages = const [
    ArduinoStatusScreen(), // 아두이노 블루투스 연결 화면
    SquatScreen(), // 메인 스쿼트 화면
    RecordHistoryScreen(), // 임시 기록 화면
    CoachingScreen(), // AI 코칭 전용 화면
  ];

  @override
  Widget build(BuildContext context) {
    final coachingProvider = Provider.of<CoachingProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: coachingProvider.currentTabIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: coachingProvider.currentTabIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          coachingProvider.setTabIndex(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: '연결 상태'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '운동',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '기록'),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'AI 코칭',
          ),
        ],
      ),
    );
  }
}