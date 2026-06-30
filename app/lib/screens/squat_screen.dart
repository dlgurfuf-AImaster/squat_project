import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/squat_provider.dart';
import '../providers/bluetooth_provider.dart';

/// AI 스쿼트 코칭 실시간 모니터링 및 제어 화면
class SquatScreen extends StatelessWidget {
  const SquatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 두 프로바이더의 상태 변화를 상단에서 정확하게 관찰
    final squatProvider = context.watch<SquatProvider>();
    final squat = squatProvider.data;
    final analyzer = squatProvider.analyzer;

    final connectionStatus = context.select<BluetoothProvider, String>(
          (p) => p.connectionStatus,
    );
    final bool isBTConnected = connectionStatus == 'CONNECTED';

    // ▶️ 운동 시작 버튼의 상태별 UI 메타데이터 정의 (컨텍스트와 프로바이더 주입)
    final switchBtnConfig = _getStartButtonConfig(context, isBTConnected, squatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 스쿼트 코치"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 1. 상태 메시지 피드백 보드
            _buildStatusCard(squat.status),
            const SizedBox(height: 30),

            // 2. 실시간 센서 신체 각도계 (게이지)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAngleGauge("허리 각도", squat.waistAngle, Colors.orange),
                _buildAngleGauge("허벅지 각도", squat.thighAngle, Colors.blue),
              ],
            ),
            const SizedBox(height: 40),

            // 3. 메인 스쿼트 성공 카운터
            Text(
              "${squat.count}",
              style: const TextStyle(fontSize: 90, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const Text(
              "SQUATS",
              style: TextStyle(fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 4. 3대 불량 자세 실시간 통계 스코어보드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "⚠️ 실시간 자세 피드백 통계",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildErrorCard("허리 과숙임", analyzer.waistErrorCount, Colors.orange),
                      _buildErrorCard("얕은 깊이", analyzer.depthErrorCount, Colors.red),
                      _buildErrorCard("상체 선행", analyzer.goodMorningCount, Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 5. 하단 제어 인터페이스 버튼셋
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // 코칭 시작 / 진행 중 버튼
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: switchBtnConfig['onPressed'] as VoidCallback?,
                      icon: Icon(switchBtnConfig['icon'] as IconData),
                      label: Text(switchBtnConfig['label'] as String),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: switchBtnConfig['color'] as Color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 통계 데이터 초기화 버튼
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        squatProvider.resetCountersOnly();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🔄 스쿼트 횟수 및 자세 통계가 초기화되었습니다.")),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("통계 초기화"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 운동 시작 버튼의 상태별 맵 구성 (🚨 누락되었던 비즈니스 액션 바인딩 수리 완료)
  Map<String, dynamic> _getStartButtonConfig(BuildContext context, bool isConnected, SquatProvider provider) {
    if (!isConnected) {
      return {
        'onPressed': null,
        'icon': Icons.bluetooth_disabled,
        'label': "연결 안됨 (대기 중)",
        'color': Colors.grey,
      };
    }
    if (provider.isReading) {
      return {
        'onPressed': null,
        'icon': Icons.hourglass_full,
        'label': "코칭 중",
        'color': Colors.teal,
      };
    }
    return {
      // 🎯 [수정] 버튼 탭 시 누락되었던 비즈니스 시동 함수를 정확히 매핑!
      'onPressed': () => _handleStartWorkout(context, provider),
      'icon': Icons.play_arrow,
      'label': "운동 시작",
      'color': Colors.blueAccent,
    };
  }

  /// 🔓 실질적인 운동 시작 시동기 구현
  void _handleStartWorkout(BuildContext context, SquatProvider provider) {
    provider.startReading(); // 1) 프로바이더의 데이터 수신 게이트 오픈!

    // 2) 사용자 피드백 안내 스낵바 출력
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🟢 실시간 스쿼트 코칭을 시작합니다!")),
    );
  }

  Widget _buildStatusCard(String status) {
    bool isWarning = status.contains("❌") || status.contains("경고");
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isWarning ? Colors.red : Colors.blueAccent, width: 2),
      ),
      child: Center(
        child: Text(
          status,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isWarning ? Colors.red : Colors.blueAccent,
          ),
        ),
      ),
    );
  }

  Widget _buildAngleGauge(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                value: (value % 180) / 180,
                strokeWidth: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text("${value.toInt()}°", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text("$count회", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}