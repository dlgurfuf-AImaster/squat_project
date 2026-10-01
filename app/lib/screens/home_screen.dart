import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/bluetooth_provider.dart';
import '../providers/coaching_provider.dart';
import '../providers/squat_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/workout_stat_calculator.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        context.read<SquatProvider>().loadLocalRecords();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이미지 사전 로딩 (첫 프레임 어두워짐 방지)
    precacheImage(
      const AssetImage('assets/images/main_icon.png'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<BluetoothProvider>();
    final squatProvider = context.watch<SquatProvider>();
    final coachingProvider = context.read<CoachingProvider>();
    final bool isBTConnected = btProvider.connectionStatus == 'CONNECTED';

    final stats = WorkoutWeeklyStats.calculate(squatProvider.localRecords); // 주간 통계 데이터 객체

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      endDrawer: const _ProfileDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 앱 타이틀 & 헤더
              const _HomeHeader(),
              const SizedBox(height: 16),

              // 2. 주간 운동 통계 칩 배지 (실데이터 연결)[cite: 4]
              _HomeStatBadges(
                streakDays: stats.streakDays,
                weeklyTotalReps: stats.weeklyTotalReps,
                maxReps: stats.maxRepsInSingle,
              ),
              const SizedBox(height: 15),

              // 3. 상단 문구 + 버튼 통합 영역
              MotivationalBanner(
                child: _HomeGridMenu(
                  coachingProvider: coachingProvider,
                  isBTConnected: isBTConnected,
                ),
              ),
              const SizedBox(height: 10),

              // 4. 3D 주간 스쿼트 리포트 (실데이터 연결)[cite: 4]
              IsometricVerticalChart(
                counts: stats.dailyCounts,
                todayIndex: stats.todayIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 1. 홈 헤더 위젯
// =============================================================================
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primarySky,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primarySky.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.home_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "SquatMate",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Builder(
          builder: (context) {
            return SizedBox(
              width: 38,
              height: 38,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.settings_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// 계정 정보 드로어
// =============================================================================
class _ProfileDrawer extends StatelessWidget {
  const _ProfileDrawer();

  static const double _floatingBarHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final double drawerWidth = MediaQuery.of(context).size.width * 0.78;
    final user = context.watch<UserProvider>().user;
    final String initial = user.name.trim().isNotEmpty ? user.name.trim()[0] : "?";
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Padding(
      padding: const EdgeInsets.only(bottom: _floatingBarHeight),
      child: Drawer(
        width: drawerWidth,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
        ),
        child: Column(
          children: [
            SizedBox(height: statusBarHeight + 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF8FAFC), width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.04,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172040),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              blurRadius: 2,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "@${user.username}",
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerMenuItem(
                    icon: Icons.person_outline_rounded,
                    iconBg: const Color(0x170284C7),
                    iconColor: const Color(0xFF0284C7),
                    label: "계정 변경하기",
                    subLabel: "닉네임 수정",
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.notifications_none_rounded,
                    iconBg: const Color(0x177C3AED),
                    iconColor: const Color(0xFF7C3AED),
                    label: "알림 설정",
                    subLabel: "운동 알림 관리",
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _DrawerMenuItem(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0x1710B981),
                    iconColor: const Color(0xFF10B981),
                    label: "개인정보 처리방침",
                    subLabel: "Privacy Policy",
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF8FAFC), width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  _DrawerMenuItem(
                    icon: Icons.logout_rounded,
                    iconBg: const Color(0x1FEF4444),
                    iconColor: const Color(0xFFEF4444),
                    label: "로그아웃",
                    subLabel: "계정에서 로그아웃",
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('로그아웃'),
                            content: const Text(
                              '로그아웃하면 이 기기에 저장된 운동 기록이 삭제될 수 있습니다.\n'
                                  '특히 서버에 동기화되지 않은 기록은 복구할 수 없습니다.\n\n'
                                  '로그아웃하시겠습니까?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text('로그아웃'),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldLogout != true) {
                        return;
                      }

                      await context.read<SquatProvider>().clearLocalRecords();
                      await ApiService().logout();

                      if (!context.mounted) return;

                      context.read<UserProvider>().clearUser();

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                            (route) => false,
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "SquatMate v1.0.0",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: const Color(0xFFCBD5E1),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String subLabel;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.subLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF172040),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 3. 주간 연속 및 목표 달성 칩 배지 그룹 (동적 조건부 이모지 적용)
// =============================================================================
class _HomeStatBadges extends StatelessWidget {
  final int streakDays;
  final int weeklyTotalReps;
  final int maxReps;

  const _HomeStatBadges({
    required this.streakDays,
    required this.weeklyTotalReps,
    required this.maxReps,
  });

  String get _streakFormattedText {
    if (streakDays == 0) {
      return "오늘 시작!";
    } else if (streakDays < 4) {
      return "${streakDays}일 연속";
    } else {
      return "🔥 ${streakDays}일 연속";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _PillChip(
          text: _streakFormattedText,
          isHighlighted: streakDays >= 4,
        ),
        SizedBox(width: 5),
        _PillChip(text: "총 ${weeklyTotalReps}회 / 주"),
        SizedBox(width: 5),
        _PillChip(text: "주간 PR ${maxReps}회"),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  final String text;
  final bool isHighlighted; // 4일 이상 연속 시 강조 여부

  const _PillChip({
    required this.text,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFEF4444) : const Color(0xFFF1F5F9),
          width: isHighlighted ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFEF4444).withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isHighlighted ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}

// =============================================================================
// 4. 2x2 그리드 메뉴
// =============================================================================
class _HomeGridMenu extends StatelessWidget {
  final CoachingProvider coachingProvider;
  final bool isBTConnected;

  const _HomeGridMenu({
    required this.coachingProvider,
    required this.isBTConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: "운동하기",
                subtitle: "Start Squat",
                imagePath: "assets/images/main_icon.png",
                isPrimary: true,
                onTap: () => coachingProvider.setTabIndex(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: "AI 코칭",
                subtitle: "AI Coaching",
                icon: Icons.auto_awesome_rounded,
                iconBgColor: const Color(0xFFF3E8FF),
                iconColor: Colors.purple,
                onTap: () {
                  coachingProvider.setTabIndex(4);
                  coachingProvider.fetchServerRecords();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                title: "운동 기록",
                subtitle: "My Records",
                icon: Icons.bar_chart_rounded,
                iconBgColor: AppTheme.primarySky.withValues(alpha: 0.12),
                iconColor: AppTheme.primarySky,
                onTap: () => coachingProvider.setTabIndex(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                title: "블루투스",
                subtitle: isBTConnected ? "연결됨" : "BT Connect",
                icon: isBTConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                iconBgColor: isBTConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                iconColor: isBTConnected ? AppTheme.accentGreen : const Color(0xFF64748B),
                onTap: () => coachingProvider.setTabIndex(1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imagePath;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? iconBgColor;
  final Color? iconColor;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.imagePath,
    required this.onTap,
    this.isPrimary = false,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primarySky : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: isPrimary
              ? [
            BoxShadow(
              color: AppTheme.primarySky.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ]
              : [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.2)
                          : (iconBgColor ?? const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: imagePath != null
                        ? Transform.translate(
                      offset: const Offset(1.0, 0.0),
                      child: Image.asset(
                        imagePath!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                        color: isPrimary
                            ? Colors.white
                            : (iconColor ?? const Color(0xFF0F172A)),
                      ),
                    )
                        : Icon(
                      icon,
                      size: 22,
                      color: isPrimary
                          ? Colors.white
                          : (iconColor ?? const Color(0xFF0F172A)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isPrimary ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: isPrimary
                              ? Colors.white.withValues(alpha: 0.8)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 5. 모티베이션 배너
// =============================================================================
class MotivationalBanner extends StatefulWidget {
  final Widget child;

  const MotivationalBanner({
    super.key,
    required this.child,
  });

  @override
  State<MotivationalBanner> createState() => _MotivationalBannerState();
}

class _MotivationalBannerState extends State<MotivationalBanner> {
  Timer? _timer;
  int _currentIndex = 0;
  bool _isVisible = true;

  static const Curve appCubicCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  final List<String> _quotes = [
    "오늘의 한계를 넘어\n내일의 나를 만나다",
    "한 번 더 내딛는 순간\n변화가 시작된다",
    "지금의 노력이 쌓여\n더 강한 내가 된다",
    "조금 더 깊게\n조금 더 천천히",
    "오늘도 끝까지 해내면\n어제보다 강해진다",
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 8500), (timer) async {
      if (!mounted) return;

      setState(() {
        _isVisible = false;
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % _quotes.length;
        _isVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 4,
          right: 4,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1300),
            reverseDuration: const Duration(milliseconds: 700),
            switchInCurve: appCubicCurve,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final double translateY = -10.0 * (1.0 - animation.value);
                  return Transform.translate(
                    offset: Offset(0.0, translateY),
                    child: Opacity(
                      opacity: animation.value,
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            child: _isVisible
                ? Container(
              key: ValueKey<int>(_currentIndex),
              alignment: Alignment.centerLeft,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primarySky.withValues(alpha: 0.75),
                      AppTheme.primarySky.withValues(alpha: 0.0),
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  _quotes[_currentIndex],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            )
                : const SizedBox.shrink(key: ValueKey<String>('empty_space')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 83.0),
          child: widget.child,
        ),
      ],
    );
  }
}

// =============================================================================
// 6. 3D 아이소메트릭 차트 카드 (정적 액자형 Empty State)
// =============================================================================
class IsometricVerticalChart extends StatelessWidget {
  final List<int> counts; // [월, 화, 수, 목, 금, 토, 일] 7개 데이터
  final int todayIndex;   // 0(월) ~ 6(일)

  const IsometricVerticalChart({
    super.key,
    required this.counts,
    required this.todayIndex,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> days = ["월", "화", "수", "목", "금", "토", "일"];
    final bool isEmpty = counts.every((count) => count == 0);

    // 이번 주 일일 최댓값을 기반으로 차트 비율 계산 (최소 30회 기준)
    final int maxInWeek = counts.reduce((a, b) => a > b ? a : b);
    final int maxCount = maxInWeek > 30 ? maxInWeek : 30;

    final Color primarySky = AppTheme.primarySky;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primarySky.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.date_range_rounded, size: 18, color: primarySky),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "주간 스쿼트 리포트",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "일일 목표 30회",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 135,
            child: isEmpty
                ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primarySky.withValues(alpha: 0.95),
                          AppTheme.primarySky.withValues(alpha: 0.35),
                        ],
                      ).createShader(bounds);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: const [
                        Text(
                          "이번 주 첫 스쿼트,",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "시작해볼까요?",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final bool isToday = index == todayIndex;
                final int count = counts[index];
                final double heightRatio = (count / maxCount).clamp(0.0, 1.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 16,
                      child: count > 0
                          ? Text(
                        "$count",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? const Color(0xFF0284C7)
                              : const Color(0xFF64748B),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 4),
                    CustomPaint(
                      size: const Size(24, 80),
                      painter: IsometricUprightCylinderPainter(
                        heightRatio: heightRatio,
                        isToday: isToday,
                        hasValue: count > 0,
                        baseColor: primarySky,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF0284C7)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 7. 3D 수직 원통 커스텀 페인터
// =============================================================================
class IsometricUprightCylinderPainter extends CustomPainter {
  final double heightRatio;
  final bool isToday;
  final bool hasValue;
  final Color baseColor;

  IsometricUprightCylinderPainter({
    required this.heightRatio,
    required this.isToday,
    required this.hasValue,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double rx = size.width / 2;
    final double ry = rx * 0.45;

    final double maxHeight = size.height - (ry * 2) - 6;
    final double fillHeight = maxHeight * heightRatio;

    final double bottomY = size.height - ry - 3;
    final double topY = bottomY - fillHeight;
    final double fullTopY = bottomY - maxHeight;

    final Color mainColor = !hasValue
        ? const Color(0xFFE2E8F0)
        : (isToday ? const Color(0xFF0284C7) : baseColor);

    final HSLColor hsl = HSLColor.fromColor(mainColor);
    final Color topCapColor = hsl.withLightness((hsl.lightness + 0.20).clamp(0.0, 1.0)).toColor();
    final Color sideDarkColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    if (hasValue) {
      final Path shadowPath = Path()
        ..moveTo(0, bottomY)
        ..lineTo(rx * 1.8, bottomY + ry * 1.5)
        ..arcToPoint(
          Offset(size.width + rx * 1.8, bottomY + ry * 1.5),
          radius: Radius.elliptical(rx, ry),
        )
        ..lineTo(size.width, bottomY)
        ..close();

      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    final Paint trackPaint = Paint()..color = const Color(0xFFF1F5F9);
    final Path trackPath = Path()
      ..moveTo(0, bottomY)
      ..lineTo(0, fullTopY)
      ..arcToPoint(
        Offset(size.width, fullTopY),
        radius: Radius.elliptical(rx, ry),
      )
      ..lineTo(size.width, bottomY)
      ..arcToPoint(
        Offset(0, bottomY),
        radius: Radius.elliptical(rx, ry),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(trackPath, trackPaint);

    if (!hasValue) return;

    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          mainColor,
          mainColor,
          sideDarkColor,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, topY - ry, size.width, fillHeight + (ry * 2)));

    final Path bodyPath = Path()
      ..moveTo(0, topY)
      ..lineTo(0, bottomY)
      ..arcToPoint(
        Offset(size.width, bottomY),
        radius: Radius.elliptical(rx, ry),
        clockwise: false,
      )
      ..lineTo(size.width, topY)
      ..arcToPoint(
        Offset(0, topY),
        radius: Radius.elliptical(rx, ry),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(bodyPath, bodyPaint);

    final Paint topCapPaint = Paint()..color = topCapColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rx, topY),
        width: size.width,
        height: ry * 2,
      ),
      topCapPaint,
    );

    if (isToday) {
      final Paint borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rx, topY),
          width: size.width,
          height: ry * 2,
        ),
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IsometricUprightCylinderPainter oldDelegate) => true;
}