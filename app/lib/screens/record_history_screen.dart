import 'package:flutter/material.dart';
import '../models/squat_record.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../dtos/squat_workout_request.dart';

class RecordHistoryScreen extends StatefulWidget {
  const RecordHistoryScreen({super.key});

  @override
  State<RecordHistoryScreen> createState() => _RecordHistoryScreenState();
}

class _RecordHistoryScreenState extends State<RecordHistoryScreen> {
  late Future<List<SquatRecord>> _recordsFuture;

  // 선택된 로컬 기록 ID 저장 집합
  final Set<int> _selectedRecordIds = {};

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  // DB에서 기록 다시 불러오기
  void _refreshRecords() {
    setState(() {
      _selectedRecordIds.clear();
      _recordsFuture = DatabaseHelper.instance.getAllRecords();
    });
  }

  // 날짜 포맷 헬퍼 (YYYY-MM-DD HH:mm)
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // ☁️ 선택된 로컬 기록들을 서버로 다중 전송하는 함수
  Future<void> _sendSelectedRecordsToServer(List<SquatRecord> allRecords) async {
    final selectedRecords = allRecords
        .where((r) => r.id != null && _selectedRecordIds.contains(r.id))
        .toList();

    if (selectedRecords.isEmpty) return;

    // 로딩 팝업 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                "☁️ 선택한 기록을 서버로 전송 중입니다...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    for (final record in selectedRecords) {
      final response = await ApiService().sendSquatRecord(
        SquatWorkoutRequest.fromRecord(record),
      );
      if (response != null) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (context.mounted) {
      Navigator.pop(context); // 로딩 팝업 닫기
    }

    if (context.mounted) {
      setState(() {
        _selectedRecordIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "☁️ 서버 전송 완료 (성공: ${successCount}건 / 실패: ${failCount}건)",
          ),
        ),
      );
    }
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

          return Column(
            children: [
              // 상단 컨트롤 바: 서버 백업 전송 버튼만 남김 (AI 분석 버튼 제거)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: Text("선택(${_selectedRecordIds.length})개 서버 백업 전송"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _selectedRecordIds.isEmpty
                        ? null
                        : () => _sendSelectedRecordsToServer(records),
                  ),
                ),
              ),

              // 기록 리스트뷰
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];

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
                            // 1. 선택 체크박스, 날짜, 삭제 버튼
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (record.id != null)
                                      Checkbox(
                                        value: _selectedRecordIds.contains(record.id),
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedRecordIds.add(record.id!);
                                            } else {
                                              _selectedRecordIds.remove(record.id!);
                                            }
                                          });
                                        },
                                      ),
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.indigo),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDate(record.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                // 개별 카드 내 삭제 버튼만 유지
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    if (record.id != null) {
                                      await DatabaseHelper.instance.deleteRecord(record.id!);
                                      _refreshRecords();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("🗑️ 해당 기록이 삭제되었습니다."),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // 2. 운동 주요 성과
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

                            // 3. 자세 오류 태그
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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