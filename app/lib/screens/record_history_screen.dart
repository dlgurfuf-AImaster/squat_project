import 'package:flutter/material.dart';
import '../models/squat_record.dart';
import '../services/database_helper.dart';

class RecordHistoryScreen extends StatefulWidget {
  const RecordHistoryScreen({super.key});

  @override
  State<RecordHistoryScreen> createState() => _RecordHistoryScreenState();
}

class _RecordHistoryScreenState extends State<RecordHistoryScreen> {
  late Future<List<SquatRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  // DB에서 기록 다시 불러오기
  void _refreshRecords() {
    setState(() {
      _recordsFuture = DatabaseHelper.instance.getAllRecords();
    });
  }

  // 날짜 포맷 헬퍼 (YYYY-MM-DD HH:mm)
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🏋️ 스쿼트 운동 기록"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRecords,
            tooltip: "새로고침",
          ),
        ],
      ),
      body: FutureBuilder<List<SquatRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("❌ 데이터를 불러오는 중 오류가 발생했습니다: ${snapshot.error}"),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "아직 저장된 스쿼트 기록이 없습니다.\n운동 후 저장을 진행해 보세요!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final totalErrors = record.waistErrorCount +
                  record.depthErrorCount +
                  record.goodMorningCount;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 날짜 및 삭제 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.indigo),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(record.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                            onPressed: () async {
                              if (record.id != null) {
                                await DatabaseHelper.instance.deleteRecord(record.id!);
                                _refreshRecords(); // 목록 갱신
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("🗑️ 해당 기록이 삭제되었습니다.")),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // 2. 운동 주요 성과 (성공 횟수)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            "성공 횟수: ${record.successCount}회",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 3. 자세 오류 분석 태그
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildErrorChip("허리 숙임", record.waistErrorCount, Colors.orange),
                          _buildErrorChip("깊이 부족", record.depthErrorCount, Colors.purple),
                          _buildErrorChip("굿모닝 자세", record.goodMorningCount, Colors.deepOrange),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 자세 오류 정보를 보여주는 칩(Chip) 위젯
  Widget _buildErrorChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        "$label: $count회",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}