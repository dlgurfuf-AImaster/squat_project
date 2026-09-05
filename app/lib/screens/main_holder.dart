import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:app/screens/home_screen.dart';
import 'package:app/screens/arduino_status_screen.dart';
import 'package:app/screens/coaching_screen.dart';
import 'package:app/screens/record_history_screen.dart';
import 'package:app/screens/squat_screen.dart';
import '../providers/coaching_provider.dart';
import '../theme/app_theme.dart';

class MainHolder extends StatefulWidget {
  const MainHolder({super.key});

  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> {
  // Index 매칭: 0(홈), 1(연결), 2(운동), 3(기록), 4(AI 코칭)
  final List<Widget> _pages = const [
    HomeScreen(),          // Index 0
    ArduinoStatusScreen(), // Index 1
    SquatScreen(),         // Index 2
    RecordHistoryScreen(), // Index 3
    CoachingScreen(),      // Index 4
  ];

  /// 탭 이동 처리 메서드
  void _onTabSelected(int index, CoachingProvider coachingProvider) {
    if (coachingProvider.currentTabIndex == index) return;

    coachingProvider.setTabIndex(index);

    // AI 코칭 탭(Index 4) 진입 시 서버 데이터 갱신
    if (index == 4) {
      coachingProvider.fetchServerRecords();
    }
  }

  /// 앱 종료 확인 다이얼로그
  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '앱 종료',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text('앱을 종료하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              '종료',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final coachingProvider = Provider.of<CoachingProvider>(context);
    final currentIndex = coachingProvider.currentTabIndex;

    return PopScope(
      canPop: false, // 시스템 기본 앱 종료 제어
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. 현재 탭이 홈(0번)이 아니라면 홈 탭으로 이동
        if (currentIndex != 0) {
          coachingProvider.setTabIndex(0);
          return;
        }

        // 2. 이미 홈 탭인 경우 종료 확인 다이얼로그 표시
        final shouldExit = await _showExitDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop(); // 앱 종료
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        extendBody: true, // 바텀바 뒤로 본문이 자연스럽게 비치도록 확장
        body: IndexedStack(
          index: currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildFloatingNavigationBar(coachingProvider, currentIndex),
      ),
    );
  }

  /// 플로팅 모던 바텀 네비게이션 바
  Widget _buildFloatingNavigationBar(CoachingProvider coachingProvider, int currentIndex) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: Colors.white.withValues(alpha: 0.88),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: AppTheme.primarySky,
                  unselectedItemColor: const Color(0xFF94A3B8),
                  selectedFontSize: 11,
                  unselectedFontSize: 11,
                  elevation: 0,
                  onTap: (index) => _onTabSelected(index, coachingProvider),
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: '홈',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.bluetooth_rounded),
                      label: '연결',
                    ),
                    // 가운데 운동(스쿼트) 탭 강조 포인트
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentIndex == 2
                              ? AppTheme.primarySky
                              : AppTheme.primarySky.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: currentIndex == 2 ? Colors.white : AppTheme.primarySky,
                          size: 20,
                        ),
                      ),
                      label: '운동',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart_rounded),
                      label: '기록',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.auto_awesome_rounded),
                      label: 'AI 코칭',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}