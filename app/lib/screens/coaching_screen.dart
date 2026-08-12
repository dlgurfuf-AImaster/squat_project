import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coaching_provider.dart';

class CoachingScreen extends StatelessWidget {
  const CoachingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 스쿼트 코칭'),
        centerTitle: true,
      ),
      body: Consumer<CoachingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Gemini AI가 스쿼트 자세를 분석하고 있습니다...'),
                ],
              ),
            );
          }

          final coaching = provider.latestCoaching;
          final errorMessage = provider.errorMessage;

          if (coaching == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    errorMessage != null ? Icons.error_outline : Icons.psychology_outlined,
                    size: 80,
                    color: errorMessage != null ? Colors.redAccent : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage ?? '아직 수신된 AI 코칭 결과가 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: errorMessage != null ? Colors.redAccent : Colors.grey,
                      fontWeight: errorMessage != null ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.setTabIndex(2), // 기록 탭으로 돌아가기
                    child: const Text('기록 탭으로 이동'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 분석 요약 카드
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              coaching.coachingType == 'SINGLE' ? '단일 세트 분석' : '종합/누적 분석',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Chip(
                              label: Text('${coaching.totalSessions}개 세트 분석됨'),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('성공', coaching.totalSuccessCount, Colors.green),
                            _buildStatItem('허리 오류', coaching.totalWaistErrorCount, Colors.orange),
                            _buildStatItem('깊이 오류', coaching.totalDepthErrorCount, Colors.red),
                            _buildStatItem('굿모닝 오류', coaching.totalGoodMorningCount, Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. AI 피드백 메시지 카드
                const Text(
                  '트레이너 AI 총평',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue.shade50,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.smart_toy, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            coaching.coachingMessage,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '$count회',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}