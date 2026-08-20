import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/squat_model.dart';
import '../providers/squat_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../theme/app_theme.dart';

/// AI 스쿼트 코칭 실시간 모니터링 및 제어 화면
class SquatScreen extends StatefulWidget {
  const SquatScreen({super.key});

  @override
  State<SquatScreen> createState() => _SquatScreenState();
}

class _SquatScreenState extends State<SquatScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이미지 사전 로딩 (첫 프레임 어두워짐 방지)
    precacheImage(
      const AssetImage('assets/images/gemini_squat_person.png'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final squatProvider = context.watch<SquatProvider>();
    final squat = squatProvider.data;

    final connectionStatus = context.select<BluetoothProvider, String>(
          (p) => p.connectionStatus,
    );
    final bool isBTConnected = connectionStatus == 'CONNECTED';

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 상단 앱 타이틀 & 블루투스 상태 헤더
              _SquatHeader(isBTConnected: isBTConnected),
              const SizedBox(height: 14),

              // 2. 실시간 자세 분석 카드 (블루투스 주석 상태 유지)
              _RealtimePostureCard(
                squat: squat,
                isBTConnected: isBTConnected,
              ),
              const SizedBox(height: 12),

              // 3. 스쿼트 카운터 카드
              _SquatCounterCard(squat: squat),
              const SizedBox(height: 12),

              // 4. 하단 액션 버튼 영역
              _ActionButtons(
                isBTConnected: isBTConnected,
                squatProvider: squatProvider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 📌 1. 상단 타이틀 및 블루투스 상태 헤더
// =============================================================================
class _SquatHeader extends StatelessWidget {
  final bool isBTConnected;

  const _SquatHeader({required this.isBTConnected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
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
              child: Center(
                child: Transform.translate(
                  offset: const Offset(1.0, 0.0), // 손수 조정해두신 위치 값 유지
                  child: Image.asset(
                    'assets/images/gemini_squat_person.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Squat Coach",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        _BTStatusChip(connected: isBTConnected),
      ],
    );
  }
}

class _BTStatusChip extends StatelessWidget {
  final bool connected;

  const _BTStatusChip({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: connected
            ? const Color.fromRGBO(16, 185, 129, 0.1)
            : const Color.fromRGBO(239, 68, 68, 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? "연결됨" : "미연결",
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.bluetooth,
            size: 13,
            color: connected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 📊 2. 실시간 자세 분석 카드 (하이브리드 피드백 반영)
// =============================================================================
class _RealtimePostureCard extends StatelessWidget {
  final dynamic squat;
  final bool isBTConnected;

  const _RealtimePostureCard({
    required this.squat,
    required this.isBTConnected,
  });

  /// 시스템 알림 + 각도 기반 실시간 하이브리드 메시지 생성 함수
  _StatusInfo _getSquatStatusInfo(SquatData squat, bool isReading) {
    // 1순위: 블루투스 연결 해제 상태
    if (!isBTConnected) {
      return _StatusInfo(
        label: "⚠️ 블루투스 기기를 연결해 주세요",
        color: const Color(0xFFEF4444),
      );
    }

    // 2순위: 운동 시작 전 (센서 읽기 안 함)
    if (!isReading) {
      return _StatusInfo(
        label: "운동 시작 버튼을 눌러주세요",
        color: const Color(0xFF94A3B8),
      );
    }

    // 3순위: Provider/Service 특수 안내 메시지 (영점, 초기화 등)
    if (squat.status.contains("영점")) {
      return _StatusInfo(
        label: squat.status,
        color: const Color(0xFF3B82F6),
      );
    } else if (squat.status.contains("초기화") || squat.status.contains("기록")) {
      return _StatusInfo(
        label: squat.status,
        color: const Color(0xFF6B7280),
      );
    }

    // 4순위: 실시간 자세 분석 코칭 (각도 수치 기반 즉시 피드백)
    // ① 허리 숙임 경고 (40도 초과)
    if (squat.waistAngle > 40.0) {
      return _StatusInfo(
        label: "허리 과숙임 경고",
        color: const Color(0xFFEF4444),
      );
    }

    // ② 허벅지 각도에 따른 깊이 가이드
    if (squat.thighAngle < 15.0) {
      return _StatusInfo(
        label: "준비 자세 (천천히 내려가세요)",
        color: const Color(0xFF94A3B8),
      );
    } else if (squat.thighAngle < 85.0) {
      return _StatusInfo(
        label: "조금 더 깊게 앉아보세요",
        color: const Color(0xFFF59E0B),
      );
    } else {
      return _StatusInfo(
        label: "✓ 정상 스쿼트",
        color: const Color(0xFF10B981),
      );
    }
  }

  Color _getWaistColor(int a) {
    if (a < 28) return const Color(0xFF10B981);
    if (a < 48) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _getThighColor(int a) {
    if (a > 75) return const Color(0xFF10B981);
    if (a > 48) return AppTheme.primarySky;
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    // SquatProvider에서 isReading 상태값 읽기
    final isReading = context.watch<SquatProvider>().isReading;
    final statusInfo = _getSquatStatusInfo(squat, isReading);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          // 1. 은은한 primarySky 조명 후광 (연꽃 효과)
          BoxShadow(
            color: AppTheme.primarySky.withValues(alpha: 0.28),
            blurRadius: 22,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
          // 2. 카드의 형태를 잡아주는 미세 그림자
          const BoxShadow(
            color: Color.fromRGBO(23, 32, 64, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "실시간 자세 분석",
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFFB0BDD0),
              letterSpacing: 1.6,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 게이지 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ArcGauge(
                  value: squat.waistAngle.toInt(),
                  max: 90,
                  label: "허리 각도",
                  color: _getWaistColor(squat.waistAngle.toInt()),
                ),
              ),
              Container(
                width: 1,
                height: 70,
                color: const Color(0xFFEAF1FB),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
              Expanded(
                child: _ArcGauge(
                  value: squat.thighAngle.toInt(),
                  max: 120,
                  label: "허벅지 각도",
                  color: _getThighColor(squat.thighAngle.toInt()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 상태 메시지 피드백 보드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: statusInfo.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusInfo.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  statusInfo.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusInfo.color,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 🔢 3. 스쿼트 카운터 카드
// =============================================================================
class _SquatCounterCard extends StatelessWidget {
  final dynamic squat;

  const _SquatCounterCard({required this.squat});

  @override
  Widget build(BuildContext context) {
    final int totalCount = squat.successCount +
        squat.waistErrorCount +
        squat.depthErrorCount +
        squat.goodMorningCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 64, 0.07),
            blurRadius: 16,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "스쿼트 카운터",
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: const Color(0xFFB0BDD0),
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "$totalCount",
                    style: GoogleFonts.anton(
                      fontSize: 38,
                      color: AppTheme.primarySky,
                      letterSpacing: 0.7,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    "회",
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: const Color(0xFF6B84A8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          _CountRow(
            label: "정상 스쿼트",
            count: squat.successCount,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 7),
          _CountRow(
            label: "허리 과숙임",
            count: squat.waistErrorCount,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 7),
          _CountRow(
            label: "얕은 깊이",
            count: squat.depthErrorCount,
            color: const Color(0xFFF97316),
          ),
          const SizedBox(height: 7),
          _CountRow(
            label: "상체 선행",
            count: squat.goodMorningCount,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF172040),
              ),
            ),
          ),
          Text(
            "$count",
            style: GoogleFonts.anton(
              fontSize: 20,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            "회",
            style: GoogleFonts.dmSans(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 🔘 4. 하단 액션 버튼 영역 (💡 홈 화면 _buildActionCard 디자인 스타일로 업데이트)
// =============================================================================
class _ActionButtons extends StatelessWidget {
  final bool isBTConnected;
  final SquatProvider squatProvider;

  const _ActionButtons({
    required this.isBTConnected,
    required this.squatProvider,
  });

  void _handleStartWorkout(BuildContext context) {
    squatProvider.startReading();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🟢 실시간 스쿼트 코칭을 시작합니다!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 블루투스 연결됨 + 운동 시작 전 상태
    if (isBTConnected && !squatProvider.isReading) {
      return _buildHomeStyleCardButton(
        title: "운동 시작",
        subtitle: "Start Workout (센서 읽기)",
        icon: Icons.play_arrow_rounded,
        isPrimary: true,
        onTap: () => _handleStartWorkout(context),
      );
    }

    // 2. 운동 중 (센서 읽기 중) 상태
    if (squatProvider.isReading) {
      return Row(
        children: [
          Expanded(
            child: _buildHomeStyleCardButton(
              title: "저장하기",
              subtitle: "Save Record",
              icon: Icons.save_alt_rounded,
              isPrimary: true,
              onTap: () async {
                bool isSaved = await squatProvider.saveCurrentSessionRecord();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSaved ? "📊 운동 기록이 저장되었습니다!" : "⚠️ 저장할 기록이 없습니다.",
                      ),
                      backgroundColor: isSaved
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildHomeStyleCardButton(
              title: "초기화",
              subtitle: "Reset Counter",
              icon: Icons.refresh_rounded,
              isPrimary: false,
              customBorderColor: const Color(0xFFFEE2E2),
              iconBgColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFEF4444),
              titleColor: const Color(0xFFEF4444),
              onTap: () {
                squatProvider.resetCountersOnly();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🔄 스쿼트 통계가 초기화되었습니다.")),
                );
              },
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// 홈 화면의 _buildActionCard 규격을 일치시킨 헬퍼 위젯
  Widget _buildHomeStyleCardButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color? customBorderColor,
    Color? iconBgColor,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Material(
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
                : Border.all(
              color: customBorderColor ?? const Color(0xFFF1F5F9),
              width: 1.2,
            ),
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
          child: Row(
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
                  color: isPrimary
                      ? Colors.white
                      : (iconColor ?? const Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPrimary
                            ? Colors.white
                            : (titleColor ?? const Color(0xFF0F172A)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 🎨 상태 정보 헬퍼 모델 및 게이지 커스텀 페인터
// =============================================================================
class _StatusInfo {
  final String label;
  final Color color;

  _StatusInfo({required this.label, required this.color});
}

class _ArcGauge extends StatelessWidget {
  final int value;
  final int max;
  final String label;
  final Color color;

  const _ArcGauge({
    required this.value,
    required this.max,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double targetRatio = (value / max).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 90,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: targetRatio),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            builder: (context, animatedRatio, child) {
              return CustomPaint(
                painter: _ArcGaugePainter(
                  value: animatedRatio,
                  activeColor: color,
                ),
              );
            },
          ),
        ),
        Text(
          "$value°",
          style: GoogleFonts.anton(
            fontSize: 28,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: const Color(0xFF8A9BB5),
          ),
        ),
      ],
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double value;
  final Color activeColor;

  _ArcGaugePainter({required this.value, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height - 10;
    final double r = (size.width - 20) / 2;

    // 1. 회색 배경 트랙
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFEAF1FB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    // 2. 활성 아크
    final Paint activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final double sweepAngle = math.pi * value;
    canvas.drawArc(rect, math.pi, sweepAngle, false, activePaint);

    // 3. 바늘 링
    final double pointerAngle = math.pi + sweepAngle;
    final double nx = cx + r * math.cos(pointerAngle);
    final double ny = cy + r * math.sin(pointerAngle);

    final Paint ringPaint = Paint()..color = activeColor;
    final Paint innerRingPaint = Paint()..color = Colors.white;

    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: Offset(nx, ny), radius: 8)),
      Colors.black,
      4,
      true,
    );

    canvas.drawCircle(Offset(nx, ny), 8, ringPaint);
    canvas.drawCircle(Offset(nx, ny), 4, innerRingPaint);

    // 4. 눈금 라벨 (0°, 120°)
    final textPainter0 = TextPainter(
      text: TextSpan(
        text: "0°",
        style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFFB0BDD0)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter0.paint(
      canvas,
      Offset(cx - r - (textPainter0.width / 2), cy + 12),
    );

    final textPainterMax = TextPainter(
      text: TextSpan(
        text: "120°",
        style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFFB0BDD0)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterMax.paint(
      canvas,
      Offset(cx + r - (textPainterMax.width / 2), cy + 12),
    );
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.activeColor != activeColor;
  }
}