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
  // Index 매칭: 0(연결), 1(운동), 2(로컬 기록), 3(AI 코칭)
  final List<Widget> _pages = const [
    ArduinoStatusScreen(), // Index 0: 아두이노 블루투스 연결 화면
    SquatScreen(),         // Index 1: 메인 스쿼트 화면
    RecordHistoryScreen(), // Index 2: 로컬 기록 및 서버 전송 화면
    CoachingScreen(),      // Index 3: AI 코칭 전용 화면
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

          // IndexedStack 특성상 탭 이동 시 initState가 재호출되지 않으므로,
          // AI 코칭 탭(Index 3) 클릭 시 서버 DB 최신 기록을 가져오도록 호출
          if (index == 3) {
            coachingProvider.fetchServerRecords();
          }
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