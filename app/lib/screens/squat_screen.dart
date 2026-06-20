import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/squat_provider.dart';

/// 스쿼트 페이지
class SquatScreen extends StatelessWidget {
  const SquatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 스쿼트 코치"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<SquatProvider>(
        builder: (context, provider, child) {
          // 얼마나 갱신? 어느 주기로?, analyzer 연결
          final squat = provider.data;
          final analyzer = provider.analyzer;

          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // 1. 상태 메시지 카드 (경고 및 성공 메시지 출력)
                _buildStatusCard(squat.status),
                const SizedBox(height: 30),

                // 2. 실시간 각도 표시 (커스텀 게이지 스타일)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAngleGauge("허리 각도", squat.waistAngle, Colors.orange),
                    _buildAngleGauge("허벅지 각도", squat.thighAngle, Colors.blue),
                  ],
                ),
                const SizedBox(height: 40),

                // 3. 메인 성공 카운트 표시
                Text(
                  "${squat.count}",
                  style: const TextStyle(
                    fontSize: 90,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const Text(
                  "SQUATS",
                  style: TextStyle(
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // 3대 불량 자세 실시간 스코어보드
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "⚠️ 실시간 자세 피드백 통계",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildErrorCard(
                            "허리 과숙임",
                            analyzer.waistErrorCount,
                            Colors.orange,
                          ),
                          _buildErrorCard(
                            "얕은 깊이",
                            analyzer.depthErrorCount,
                            Colors.red,
                          ),
                          _buildErrorCard(
                            "상체 선행",
                            analyzer.goodMorningCount,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 4. 컨트롤 버튼들
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 아두이노 연결 버튼
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                provider.startBluetoothWorkout();
                              },
                              icon: const Icon(Icons.bluetooth_connected),
                              label: const Text("아두이노 연결"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 여러가지 부가 버튼들
                      Row(
                        children: [
                          // 가상 테스트
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => provider.startMocking(),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("가상 테스트"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 통계 초기화 버튼
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                provider.reset();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("모든 운동 통계가 초기화되었습니다."),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text("통계 초기화"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // 상태 메시지 빌더 (X 나 경고가 있으면 빨강 아니면 파랑)
  Widget _buildStatusCard(String status) {
    bool isWarning = status.contains("❌") || status.contains("경고");
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isWarning ? Colors.red : Colors.blueAccent,
          width: 2,
        ),
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

  // 각도 게이지 빌더
  Widget _buildAngleGauge(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            Text(
              "${value.toInt()}°",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // 오류 통계 시각화용 카드 위젯 빌더
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "$count회",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
