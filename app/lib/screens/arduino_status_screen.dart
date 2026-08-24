import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/squat_provider.dart';
import '../providers/bluetooth_provider.dart';

/// 블루투스 아두이노 센서 연결 및 상태 관리 화면
class ArduinoStatusScreen extends StatelessWidget {
  const ArduinoStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final String connectionStatus = bluetoothProvider.connectionStatus;
    final bool isConnecting = connectionStatus == 'CONNECTING';
    final bool isConnected = connectionStatus == 'CONNECTED';

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 상단 앱 타이틀 헤더 (Bluetooth)
              _buildHeader(),
              const SizedBox(height: 20),

              // 2. 메인 착용 가이드 및 상태 카드 (이미지 플레이스홀더 포함)
              _buildMainSensorGuideCard(
                isConnected: isConnected,
                isConnecting: isConnecting,
              ),
              const SizedBox(height: 16),

              // 3. 센서별 개별 상태 카운터 (가로 2개 배치 - 애니메이션 서브카드 적용)
              Row(
                children: [
                  Expanded(
                    child: PulsingSensorSubCard(
                      title: "허리 센서",
                      deviceName: "BT05_WAIST",
                      isConnected: isConnected,
                      icon: Icons.developer_board_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PulsingSensorSubCard(
                      title: "허벅지 센서",
                      deviceName: "BT05_THIGH",
                      isConnected: isConnected,
                      icon: Icons.memory_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. 하단 동작 실행 버튼 (홈 화면 카드 버튼 테마)
              _buildActionButton(
                context: context,
                isConnecting: isConnecting,
                isConnected: isConnected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 📌 1. 상단 타이틀 헤더 (홈 화면 양식 이식)
  // ===========================================================================
  Widget _buildHeader() {
    return Row(
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
              Icons.bluetooth_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Bluetooth",
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

// ===========================================================================
  // 🖼️ 메인 착용 가이드 & 연결 안내 카드 (태그 윗면 중앙 직선 연결)
  // ===========================================================================
  Widget _buildMainSensorGuideCard({
    required bool isConnected,
    required bool isConnecting,
  }) {
    final Color activeColor = isConnected
        ? AppTheme.accentGreen
        : isConnecting
        ? const Color(0xFFF59E0B)
        : const Color(0xFF94A3B8);

    // 📍 1. 신체 이미지 상의 실제 센서 포인트 좌표
    const Offset waistDotPos = Offset(105, 140);
    const Offset thighDotPos = Offset(213, 202);

    // 🏷️ 2. 태그 직사각형 "윗면 중앙" 접점 좌표
    const Offset waistTagAttach = Offset(54, 164);   // 허리 태그 top: 160의 윗면 중앙
    const Offset thighTagAttach = Offset(267, 255);  // 허벅지 태그 bottom: 30의 윗면 중앙

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySky.withValues(alpha: 0.28),
            blurRadius: 22,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color.fromRGBO(23, 32, 64, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 타이틀
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "센서 부착 위치 및 상태",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                _buildStatusChip(
                  isConnected: isConnected,
                  isConnecting: isConnecting,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 💡 메인 그래픽 레이어 (Stack)
          SizedBox(
            height: 325,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double centerX = width / 2;

                // 중앙 정렬 기준 오프셋 계산
                final Offset actualWaistDot = Offset(centerX + (waistDotPos.dx - 162.5), waistDotPos.dy);
                final Offset actualThighDot = Offset(centerX + (thighDotPos.dx - 162.5), thighDotPos.dy);
                final Offset actualWaistTag = Offset(centerX + (waistTagAttach.dx - 162.5), waistTagAttach.dy);
                final Offset actualThighTag = Offset(centerX + (thighTagAttach.dx - 162.5), thighTagAttach.dy);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // LAYER 1: 스쿼트 인체 와이어프레임 배경
                    Image.asset(
                      'assets/images/body_wireframe.png',
                      fit: BoxFit.contain,
                      height: 325,
                    ),

                    // LAYER 2: LED 점과 태그 윗면 중앙을 잇는 직선
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _HudLinePainter(
                          waistDot: actualWaistDot,
                          waistTag: actualWaistTag,
                          thighDot: actualThighDot,
                          thighTag: actualThighTag,
                          activeColor: activeColor,
                          isConnected: isConnected,
                        ),
                      ),
                    ),

                    // LAYER 3: 신체 부위 타겟 LED 점 (허리)
                    Positioned(
                      left: actualWaistDot.dx - 9,
                      top: actualWaistDot.dy - 9,
                      child: _buildGlowingLedDot(activeColor, isConnected),
                    ),

                    // LAYER 3: 신체 부위 타겟 LED 점 (허벅지)
                    Positioned(
                      left: actualThighDot.dx - 9,
                      top: actualThighDot.dy - 9,
                      child: _buildGlowingLedDot(activeColor, isConnected),
                    ),

                    // LAYER 4: 말풍선 태그 (허리 센서)
                    Positioned(
                      top: 160,
                      left: 1,
                      child: _buildMinimalPinTag(
                        title: "허리 센서",
                        subtitle: "BT05_WAIST",
                        isConnected: isConnected,
                        activeColor: activeColor,
                        isLeftAlign: true,
                      ),
                    ),

                    // LAYER 4: 말풍선 태그 (허벅지 센서)
                    Positioned(
                      bottom: 30,
                      right: 6,
                      child: _buildMinimalPinTag(
                        title: "허벅지 센서",
                        subtitle: "BT05_THIGH",
                        isConnected: isConnected,
                        activeColor: activeColor,
                        isLeftAlign: false,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 💡 타겟 신체 부위에 콕 찍히는 발광 LED 점 위젯
  Widget _buildGlowingLedDot(Color activeColor, bool isConnected) {
    return Container(
      width: 18,
      height: 18,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: activeColor.withValues(alpha: isConnected ? 0.6 : 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: activeColor,
          shape: BoxShape.circle,
          boxShadow: isConnected
              ? [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.8),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ]
              : null,
        ),
      ),
    );
  }

  /// 카드 위에서 깔끔하게 떠 있는 라이트 핀 태그
  Widget _buildMinimalPinTag({
    required String title,
    required String subtitle,
    required bool isConnected,
    required Color activeColor,
    required bool isLeftAlign,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? activeColor.withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeftAlign) ...[
            _buildPulseDot(activeColor, isConnected),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment:
            isLeftAlign ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8), // #94A3B8 슬레이트 그레이
                ),
              ),
            ],
          ),
          if (!isLeftAlign) ...[
            const SizedBox(width: 6),
            _buildPulseDot(activeColor, isConnected),
          ],
        ],
      ),
    );
  }

  /// 상태 인디케이터 Dot
  Widget _buildPulseDot(Color color, bool isConnected) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isConnected
            ? [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ]
            : null,
      ),
    );
  }
  Widget _buildStatusChip({
    required bool isConnected,
    required bool isConnecting,
  }) {
    final Color color = isConnected
        ? AppTheme.accentGreen
        : isConnecting
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    final String text = isConnected
        ? "연결됨"
        : isConnecting
        ? "검색 중"
        : "미연결";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📱 3. 허리/허벅지 센서 서브 카드 (가로 배치)
  // ===========================================================================
  Widget _buildSensorSubCard({
    required String title,
    required String deviceName,
    required bool isConnected,
    required IconData icon,
  }) {
    final Color activeColor =
    isConnected ? AppTheme.accentGreen : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 64, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: activeColor),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            deviceName,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConnected ? "통신 중" : "미연결",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🔘 4. 하단 버튼 영역 (홈 화면 버튼 디자인 테마 이식)
  // ===========================================================================
  Widget _buildActionButton({
    required BuildContext context,
    required bool isConnecting,
    required bool isConnected,
  }) {
    if (isConnecting) {
      return _buildHomeStyleCardButton(
        title: "센서 연결 시도 중...",
        subtitle: "Connecting to sensors",
        icon: Icons.bluetooth_searching_rounded,
        isLoading: true,
        isPrimary: true,
        onTap: () {},
      );
    }

    if (isConnected) {
      return _buildHomeStyleCardButton(
        title: "모든 연결 해제하기",
        subtitle: "Disconnect All Devices",
        icon: Icons.power_settings_new_rounded,
        isPrimary: false,
        customBorderColor: const Color(0xFFFEE2E2),
        iconBgColor: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFEF4444),
        titleColor: const Color(0xFFEF4444),
        onTap: () => _disconnectDevice(context),
      );
    }

    return _buildHomeStyleCardButton(
      title: "센서 모듈 연결하기",
      subtitle: "Scan & Connect Sensors",
      icon: Icons.bluetooth_searching_rounded,
      isPrimary: true,
      onTap: () => _startScanAndConnect(context),
    );
  }

  /// 홈 화면 액션 카드 스타일 버튼 헬퍼 위젯
  Widget _buildHomeStyleCardButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isLoading = false,
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
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.2)
                      : (iconBgColor ?? const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPrimary
                            ? Colors.white
                            : (titleColor ?? const Color(0xFF0F172A)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ⚡ 비즈니스 로직 메서드 (기존 기능 100% 유지)
  // ===========================================================================
  void _startScanAndConnect(BuildContext context) async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    try {
      await bluetoothProvider.startBluetoothWorkout(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('연결 실패: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _disconnectDevice(BuildContext context) async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    final squatProvider = context.read<SquatProvider>();

    await bluetoothProvider.disconnectArduino(squatProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모든 아두이노 연결이 해제되었습니다.')),
    );
  }
}

// =============================================================================
// ✏️ 직선 연결선 커스텀 페인터 (LED 점 <-> 말풍선 태그)
// =============================================================================
class _HudLinePainter extends CustomPainter {
  final Offset waistDot;
  final Offset waistTag;
  final Offset thighDot;
  final Offset thighTag;
  final Color activeColor;
  final bool isConnected;

  _HudLinePainter({
    required this.waistDot,
    required this.waistTag,
    required this.thighDot,
    required this.thighTag,
    required this.activeColor,
    required this.isConnected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = isConnected
          ? activeColor.withValues(alpha: 0.8)
          : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint dotJointPaint = Paint()
      ..color = isConnected ? activeColor : const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    // 1. 허리 센서 직선 (Dot -> 태그)
    canvas.drawLine(waistDot, waistTag, linePaint);
    canvas.drawCircle(waistTag, 2.5, dotJointPaint); // 태그 접점 원형 관절

    // 2. 허벅지 센서 직선 (Dot -> 태그)
    canvas.drawLine(thighDot, thighTag, linePaint);
    canvas.drawCircle(thighTag, 2.5, dotJointPaint); // 태그 접점 원형 관절
  }

  @override
  bool shouldRepaint(covariant _HudLinePainter oldDelegate) {
    return oldDelegate.activeColor != activeColor ||
        oldDelegate.isConnected != isConnected ||
        oldDelegate.waistDot != waistDot ||
        oldDelegate.thighDot != thighDot ||
        oldDelegate.waistTag != waistTag ||
        oldDelegate.thighTag != thighTag;
  }
}

// =============================================================================
// 🫁 들숨날숨 숨쉬는(Breathing Glow) 스타일의 센서 서브 카드
// =============================================================================
class PulsingSensorSubCard extends StatefulWidget {
  final String title;
  final String deviceName;
  final bool isConnected;
  final IconData icon;

  const PulsingSensorSubCard({
    super.key,
    required this.title,
    required this.deviceName,
    required this.isConnected,
    required this.icon,
  });

  @override
  State<PulsingSensorSubCard> createState() => _PulsingSensorSubCardState();
}

class _PulsingSensorSubCardState extends State<PulsingSensorSubCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();

    // 들숨(1.5초) <-> 날숨(1.5초) 왕복 3.0초 주기
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 유기적인 호흡 곡선 (easeInOut)
    _breathAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.isConnected) {
      _controller.repeat(reverse: true); // 0.0 -> 1.0 -> 0.0 반복 왕복
    }
  }

  @override
  void didUpdateWidget(covariant PulsingSensorSubCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
    widget.isConnected ? AppTheme.accentGreen : const Color(0xFF94A3B8);

    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (context, child) {
        // 0.0(가장 옅음) ~ 1.0(가장 선명함)을 부드럽게 오가는 값
        final double breathValue = _breathAnimation.value;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            // 테두리 빛깔이 들숨 시 밝아지고 날숨 시 은은해짐
            border: Border.all(
              color: widget.isConnected
                  ? AppTheme.accentGreen.withValues(alpha: 0.2 + (breathValue * 0.4))
                  : const Color(0xFFF1F5F9),
              width: 1.2,
            ),
            boxShadow: [
              if (widget.isConnected) ...[
                // 🟢 연결됨: 호흡에 따라 번지는 후광 효과
                BoxShadow(
                  color: AppTheme.accentGreen.withValues(alpha: 0.12 + (breathValue * 0.35)),
                  blurRadius: 6 + (breathValue * 12),  // 6px -> 18px 확대
                  spreadRadius: 1 + (breathValue * 3),  // 1px -> 4px 퍼짐
                  offset: const Offset(0, 3),
                ),
              ] else ...[
                // ⚪ 미연결: 일반 고정 그림자
                const BoxShadow(
                  color: Color.fromRGBO(23, 32, 64, 0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12 + (widget.isConnected ? breathValue * 0.08 : 0.0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 20, color: activeColor),
                  ),

                  // 우측 상단 들숨날숨 펄스 Dot
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.isConnected)
                        Container(
                          width: 8 + (breathValue * 6),
                          height: 8 + (breathValue * 6),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.4 - (breathValue * 0.25)),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.deviceName,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isConnected ? "통신 중" : "미연결",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}