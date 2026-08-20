import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/squat_provider.dart';
import '../providers/coaching_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이미지 사전 로딩 (첫 프레임 어두워짐 방지)
    precacheImage(
      const AssetImage('assets/images/running_woman_icon.png'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final btProvider = context.watch<BluetoothProvider>();
    final squatProvider = context.watch<SquatProvider>();
    final coachingProvider = context.read<CoachingProvider>();
    final bool isBTConnected = btProvider.connectionStatus == 'CONNECTED';

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단 앱 타이틀 & 헤더
              _buildHeader(),
              const SizedBox(height: 8),

              // 2. 환영 메시지
              const Text(
                "Good morning, 김민준 ✍️  ·  오늘도 파이팅!",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // 3. 주간 운동 통계 칩 배지 (3종)
              _buildStatBadges(squatProvider.data.successCount),
              const SizedBox(height: 20),

              // 4. 상단 문구 + 슬림해진 버튼 통합 영역
              MotivationalBanner(
                child: _buildGridMenu(context, coachingProvider, isBTConnected),
              ),

              const SizedBox(height: 10),

              // ✏️ 이번 주 스쿼트 달성률 그래픽 카드
              const IsometricVerticalChart(),
            ],
          ),
        ),
      ),
    );
  }

  /// 상단 앱 타이틀 영역
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 38,  // 원 크기 고정 (기존 22 + 패딩 8*2)
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
          child: Center(
            child: Image.asset(
              'assets/images/running_woman_icon.png',
              width: 22,
              height: 22,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Health Coach",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  /// 주간 연속 및 목표 달성 칩 배지
  Widget _buildStatBadges(int currentSquatCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPillChip("🔥 7일 연속"),
        _buildPillChip("💪 324회 / 주"),
        _buildPillChip("🏆 최고 ${currentSquatCount > 85 ? currentSquatCount : 85}개"),
      ],
    );
  }

  Widget _buildPillChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  /// 2x2 그리드 메뉴
  Widget _buildGridMenu(
      BuildContext context,
      CoachingProvider coachingProvider,
      bool isBTConnected,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: "운동하기",
                subtitle: "Start Workout",
                icon: Icons.show_chart_rounded,
                isPrimary: true,
                onTap: () {
                  coachingProvider.setTabIndex(2);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
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
              child: _buildActionCard(
                title: "운동 기록",
                subtitle: "My Records",
                icon: Icons.bar_chart_rounded,
                iconBgColor: AppTheme.primarySky.withValues(alpha: 0.12),
                iconColor: AppTheme.primarySky,
                onTap: () {
                  coachingProvider.setTabIndex(3);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: "블루투스",
                subtitle: isBTConnected ? "연결됨" : "BT Connect",
                icon: isBTConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                iconBgColor: isBTConnected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                iconColor: isBTConnected ? AppTheme.accentGreen : const Color(0xFF64748B),
                onTap: () {
                  coachingProvider.setTabIndex(1);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color? iconBgColor,
    Color? iconColor,
  }) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Material(
        color: isPrimary ? AppTheme.primarySky : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: isPrimary
                  ? null
                  : Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
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
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : (iconBgColor ?? const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isPrimary ? Colors.white : (iconColor ?? const Color(0xFF0F172A)),
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
                      style: TextStyle(
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
    );
  }
}

// =============================================================================
// App.tsx 커스텀 Cubic-Bezier 반영 모티베이션 배너
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
    "오늘의 한계가\n내일의 시작이다",
    "스쿼트 하나가\n모든 걸 바꾼다",
    "땀은\n거짓말하지 않는다",
    "포기하는 순간\n성장도 멈춘다",
    "강해지고 싶다면\n지금 시작하라",
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
          padding: const EdgeInsets.only(top: 75.0),
          child: widget.child,
        ),
      ],
    );
  }
}

class IsometricVerticalChart extends StatelessWidget {
  const IsometricVerticalChart({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> days = ["월", "화", "수", "목", "금", "토", "일"];
    final List<int> counts = [45, 60, 0, 85, 50, 0, 0];
    const int todayIndex = 3; // 목요일 (오늘)
    const int maxCount = 100;

    final Color primarySky = AppTheme.primarySky;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더
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
                    child: Icon(Icons.bar_chart_rounded, size: 18, color: primarySky),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "3D 주간 스쿼트 리포트",
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
                  "목표 80회",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. 📊 3D 수직 원통 차트 (오늘 날짜 딥 블루 복원)
          SizedBox(
            height: 145,
            child: Row(
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
                          color: isToday ? const Color(0xFF0284C7) : const Color(0xFF64748B), // 💡 오늘 딥 블루 복원
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 4),

                    // 아이소메트릭 수직 원통
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

                    // 요일 라벨
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? const Color(0xFF0284C7) : const Color(0xFF94A3B8), // 💡 오늘 딥 블루 복원
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
// 🧊 아이소메트릭 수직 원통 페인터 (오늘 날짜 딥 블루 복원)
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

    // 💡 [복원] 오늘 날짜인 경우 선명한 딥 블루(0xFF0284C7) 사용
    final Color mainColor = !hasValue
        ? const Color(0xFFE2E8F0)
        : (isToday ? const Color(0xFF0284C7) : baseColor);

    final HSLColor hsl = HSLColor.fromColor(mainColor);
    final Color topCapColor = hsl.withLightness((hsl.lightness + 0.20).clamp(0.0, 1.0)).toColor();
    final Color sideDarkColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    // A. 바닥 3D 대각선 그림자
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

    // B. 비어있는 슬롯 트랙
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

    // C. 원통 수직 몸통
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

    // D. 위에서 내려다보는 타원 뚜껑 (Top Cap)
    final Paint topCapPaint = Paint()..color = topCapColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rx, topY),
        width: size.width,
        height: ry * 2,
      ),
      topCapPaint,
    );

    // 오늘 날짜 원통 상단에 테두리 하이라이트
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