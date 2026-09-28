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
  static const List<Widget> _pages = [
    HomeScreen(),          // Index 0
    ArduinoStatusScreen(), // Index 1
    SquatScreen(),         // Index 2
    RecordHistoryScreen(), // Index 3
    CoachingScreen(),      // Index 4
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 탭 바 아이콘 이미지 사전 로딩
    precacheImage(
      const AssetImage('assets/images/main_icon.png'),
      context,
    );
  }

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
    final coachingProvider = context.watch<CoachingProvider>();
    final currentIndex = coachingProvider.currentTabIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (currentIndex != 0) {
          coachingProvider.setTabIndex(0);
          return;
        }

        final shouldExit = await _showExitDialog();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        extendBody: true,
        body: IndexedStack(
          index: currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildFloatingNavigationBar(coachingProvider, currentIndex),
      ),
    );
  }

  /// 플로팅 모던 바텀 네비게이션 바 (Custom Row 방식)
  Widget _buildFloatingNavigationBar(CoachingProvider coachingProvider, int currentIndex) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        height: 64,
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
              child: Row(
                children: [
                  _buildNavItem(Icons.home_rounded, 0, currentIndex, coachingProvider),
                  _buildNavItem(Icons.bluetooth_rounded, 1, currentIndex, coachingProvider),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabSelected(2, coachingProvider),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: _buildCenterSquatIcon(currentIndex == 2),
                      ),
                    ),
                  ),
                  _buildNavItem(Icons.bar_chart_rounded, 3, currentIndex, coachingProvider),
                  _buildNavItem(Icons.auto_awesome_rounded, 4, currentIndex, coachingProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 일반 아이콘 탭 아이템
  Widget _buildNavItem(
      IconData icon,
      int index,
      int currentIndex,
      CoachingProvider coachingProvider,
      ) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index, coachingProvider),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? AppTheme.primarySky : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  /// 중앙 스쿼트 강조 아이콘 위젯
  Widget _buildCenterSquatIcon(bool isSelected) {
    return Transform.translate(
      offset: const Offset(0, -2),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primarySky
              : AppTheme.primarySky.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppTheme.primarySky.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Center(
          child: Transform.translate(
            offset: const Offset(1, 0),
            child: Image.asset(
              'assets/images/main_icon.png',
              width: 38,
              height: 38,
              color: isSelected ? Colors.white : AppTheme.primarySky,
            ),
          ),
        ),
      ),
    );
  }
}