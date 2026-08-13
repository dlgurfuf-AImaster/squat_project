import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coaching_provider.dart';
import '../dtos/aggregate_coaching_request.dart';

class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen> {
  // 선택된 서버 기록 ID 목록
  final Set<int> _selectedServerIds = {};

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 서버 DB 기록 목록 자동 로드
    Future.microtask(() {
      Provider.of<CoachingProvider>(context, listen: false).fetchServerRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI 스쿼트 코칭'),
        centerTitle: true,
        // 새로고침 버튼 (서버 데이터 다시 불러오기)
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _selectedServerIds.clear());
              Provider.of<CoachingProvider>(context, listen: false).fetchServerRecords();
            },
          ),
        ],
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
          final serverRecords = provider.serverRecords;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. AI 코칭 요청 컨트롤 버튼 영역
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.auto_awesome),
                            label: Text("선택한 (${_selectedServerIds.length})개 데이터 AI 분석 요청"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _selectedServerIds.isEmpty
                                ? null
                                : () async {
                              if (_selectedServerIds.length == 1) {
                                // 1개 선택 시: 선택된 ID에 해당하는 객체를 찾아서 uuid 추출 후 전달
                                final selectedRecord = serverRecords.firstWhere(
                                      (r) => r.id == _selectedServerIds.first,
                                );
                                await provider.requestSingleCoaching(selectedRecord.uuid);
                              } else {
                                // 다중 선택 시 집계 분석
                                await provider.requestAggregateCoaching(
                                  AggregateCoachingRequest.byIds(_selectedServerIds.toList()),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. AI 분석 결과 표시 영역 (있는 경우)
                if (coaching != null) ...[
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
                                coaching.coachingType == 'SINGLE' ? '단일 세트 분석 결과' : '종합/누적 분석 결과',
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
                              _buildStatItem('깊이 오류', coaching.totalDepthErrorCount, Colors.purple),
                              _buildStatItem('굿모닝 오류', coaching.totalGoodMorningCount, Colors.deepOrange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // AI 피드백 메시지 카드
                  Card(
                    color: Colors.blue.shade50,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.smart_toy, color: Colors.indigo, size: 28),
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
                  const SizedBox(height: 24),
                ] else if (errorMessage != null) ...[
                  Center(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. 서버 DB 저장 기록 선택 목록 영역
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📂 서버 저장 운동 기록 선택',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '총 ${serverRecords.length}개',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (serverRecords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        '서버에 저장된 스쿼트 기록이 없습니다.\n[기록 탭]에서 서버로 데이터를 백업 전송해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: serverRecords.length,
                    itemBuilder: (context, index) {
                      final record = serverRecords[index];
                      final isSelected = _selectedServerIds.contains(record.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          activeColor: Colors.indigo,
                          title: Text(
                            "기록 시간: ${record.recordTime}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            "성공: ${record.successCount}회 / 허리: ${record.waistErrorCount}회 / 깊이: ${record.depthErrorCount}회 / 굿모닝: ${record.goodMorningCount}회",
                            style: const TextStyle(fontSize: 12),
                          ),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedServerIds.add(record.id);
                              } else {
                                _selectedServerIds.remove(record.id);
                              }
                            });
                          },
                        ),
                      );
                    },
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