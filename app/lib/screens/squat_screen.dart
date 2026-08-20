import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFFF2F7FC),
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
// 📊 2. 실시간 자세 분석 카드
// =============================================================================
class _RealtimePostureCard extends StatelessWidget {
  final dynamic squat;
  final bool isBTConnected;

  const _RealtimePostureCard({
    required this.squat,
    required this.isBTConnected,
  });

  _StatusInfo _getSquatStatusInfo(String rawStatus) {
    if (rawStatus.contains("정상")) {
      return _StatusInfo(label: "✓ 정상 자세", color: const Color(0xFF10B981));
    }
    if (rawStatus.contains("허리 과숙임") || rawStatus.contains("경고")) {
      return _StatusInfo(label: "⚠ 허리 과숙임", color: const Color(0xFFF59E0B));
    }
    if (rawStatus.contains("얕은")) {
      return _StatusInfo(label: "⚠ 얕은 깊이", color: const Color(0xFFF97316));
    }
    if (rawStatus.contains("상체")) {
      return _StatusInfo(label: "⚠ 상체 선행", color: const Color(0xFFEF4444));
    }
    return _StatusInfo(label: "대기 중...", color: const Color(0xFF94A3B8));
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
    final statusInfo = _getSquatStatusInfo(squat.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
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

          // 💡 [임시 수정] 블루투스 조건문 주석 처리 (나중에 주석 해제하면 복구됨) TODO
          // if (isBTConnected) ...[
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
              color: statusInfo.color.withOpacity(0.08),
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
          // ] else ...[
          //   // 미연결 상태 안내
          //   Padding(
          //     padding: const EdgeInsets.symmetric(vertical: 12),
          //     child: Column(
          //       children: [
          //         Container(
          //           width: 56,
          //           height: 56,
          //           decoration: BoxDecoration(
          //             color: const Color.fromRGBO(239, 68, 68, 0.08),
          //             borderRadius: BorderRadius.circular(18),
          //           ),
          //           child: const Icon(
          //             Icons.bluetooth,
          //             color: Color(0xFFEF4444),
          //             size: 26,
          //           ),
          //         ),
          //         const SizedBox(height: 10),
          //         Text(
          //           "센서 미연결 상태입니다\n운동을 시작하려면 기기를 연결해 주세요",
          //           textAlign: TextAlign.center,
          //           style: GoogleFonts.dmSans(
          //             fontSize: 13,
          //             color: const Color(0xFF94A3B8),
          //             height: 1.5,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
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
        color: color.withOpacity(0.09),
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
// 🔘 4. 하단 액션 버튼 영역
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
    if (isBTConnected && !squatProvider.isReading) {
      return ElevatedButton(
        onPressed: () => _handleStartWorkout(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primarySky,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: Text(
          "운동 시작 (센서 읽기)",
          style: GoogleFonts.anton(
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    if (squatProvider.isReading) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
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
              icon: const Icon(Icons.save_alt, color: Colors.white, size: 19),
              label: Text(
                "저장하기",
                style: GoogleFonts.anton(
                  fontSize: 15,
                  color: Colors.white,
                  letterSpacing: 0.7,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primarySky,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                squatProvider.resetCountersOnly();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🔄 스쿼트 통계가 초기화되었습니다.")),
                );
              },
              icon: const Icon(Icons.refresh, color: Color(0xFFEF4444), size: 19),
              label: Text(
                "초기화",
                style: GoogleFonts.anton(
                  fontSize: 15,
                  color: const Color(0xFFEF4444),
                  letterSpacing: 0.7,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(
                    color: Color.fromRGBO(239, 68, 68, 0.22),
                    width: 1.5,
                  ),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
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