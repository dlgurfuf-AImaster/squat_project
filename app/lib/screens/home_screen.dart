import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/squat_provider.dart';
import '../providers/coaching_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              const SizedBox(height: 24),

              // 3. 동기부여 메인 배너 (✏️ [수정] 애플 Hello 감성 인디케이터 없는 순수 배경 배너)
              const MotivationalBanner(),
              const SizedBox(height: 10),

              // 4. 주간 운동 통계 칩 배지 (3종)
              _buildStatBadges(squatProvider.data.successCount),
              const SizedBox(height: 24),

              // 5. 메인 기능 2x2 그리드 메뉴
              _buildGridMenu(context, coachingProvider, isBTConnected),
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
          padding: const EdgeInsets.all(8),
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
          child: Image.asset(
            'assets/images/running_woman_icon.png', // 👈 추가한 이미지 에셋 경로
            width: 22,
            height: 22,
            color: Colors.white, // 검은색 실루엣 이미지를 흰색으로 자동 전환해 줍니다
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
            const SizedBox(width: 16),
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: "운동 기록",
                subtitle: "My Records",
                icon: Icons.bar_chart_rounded,
                iconBgColor: const Color(0xFFE0F2FE),
                iconColor: AppTheme.primarySky,
                onTap: () {
                  coachingProvider.setTabIndex(3);
                },
              ),
            ),
            const SizedBox(width: 16),
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
      aspectRatio: 1.05,
      child: Material(
        color: isPrimary ? AppTheme.primarySky : Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: isPrimary
                  ? null
                  : Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: isPrimary
                  ? [
                BoxShadow(
                  color: AppTheme.primarySky.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : (iconBgColor ?? const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isPrimary ? Colors.white : (iconColor ?? const Color(0xFF0F172A)),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
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
// ✏️ [리뉴얼] 배경 속으로 거의 스며드는 은은한 한 줄 파란색 문구 배너
// =============================================================================
class MotivationalBanner extends StatefulWidget {
  const MotivationalBanner({super.key});

  @override
  State<MotivationalBanner> createState() => _MotivationalBannerState();
}

class _MotivationalBannerState extends State<MotivationalBanner> {
  Timer? _timer;
  int _currentIndex = 0;

// ✏️ 슬림 한 줄 배너 전용 동기부여 문구 10종
  final List<String> _quotes = [
    "오늘도 시작해볼까요?",
    "오늘 흘린 땀은 내일의 자신감",
    "나를 바꾸는 가장 확실한 시간",
    "작은 실천이 만드는 기분 좋은 변화",
    "내일의 나에게 선물하는 오늘의 운동",
    "지속하는 힘이 곧 당신의 실력입니다",
    "한 번의 스쿼트로 시작하는 건강한 하루",
    "오늘도 나와의 약속을 지키는 중",
    "꾸준함이 모여 완벽함을 만듭니다",
    "바른 자세가 만드는 건강한 에너지",
    "포기하지 않는 당신을 응원합니다",
  ];

  @override
  void initState() {
    super.initState();

    // ✏️ 8초마다 은은하게 전환
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _quotes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: double.infinity,
        height: 64, // 👈 [수정] 부담없이 안착되는 슬림한 높이
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        decoration: BoxDecoration(
          // ✏️ [변경 1] 메인 배경과 거의 구분이 안 될 정도로 은은한 배경 그라데이션
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE0F7FE).withValues(alpha: 0.35), // 아주 살짝만 도는 하늘색 빛
              AppTheme.lightBackground,                       // 배경색으로 자연스럽게 스며듦
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          // ✏️ 필요시 경계선도 아주 미세하게만 주고 싶다면 아래 border 주석을 해제할 수 있습니다.
          // border: Border.all(color: AppTheme.primarySky.withValues(alpha: 0.08), width: 1),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 1800), // 부드러운 1.8초 페이드
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Container(
            key: ValueKey<int>(_currentIndex),
            alignment: Alignment.centerLeft,
            width: double.infinity,
            child: _buildBannerText(_quotes[_currentIndex]),
          ),
        ),
      ),
    );
  }

  /// ✏️ [변경 2] ShaderMask(그라데이션)를 제거하고 단색 파란색 Text로 변경
  Widget _buildBannerText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        // ✏️ 시선을 너무 끌지 않도록 차분하게 정돈된 파란색
        color: AppTheme.primarySky.withValues(alpha: 0.85),
        letterSpacing: -0.3,
      ),
    );
  }
}