import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/squat_record.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../dtos/squat_workout_request.dart';
import '../theme/app_theme.dart';

class RecordHistoryScreen extends StatefulWidget {
  const RecordHistoryScreen({super.key});

  @override
  State<RecordHistoryScreen> createState() => _RecordHistoryScreenState();
}

class _RecordHistoryScreenState extends State<RecordHistoryScreen> {
  late Future<List<SquatRecord>> _recordsFuture;

  // 선택된 로컬 기록 ID 저장 집합
  final Set<int> _selectedRecordIds = {};

  // UI 상태 관리 (달력형 / 나열형, 정렬 기준)
  bool _isCalendarView = true;
  bool _isAscending = false;

  // 캘린더 기준 날짜 및 PageController 상태
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 2000년 1월을 기준(인덱스 0)으로 현재 달의 초기 인덱스 계산
    final initialPage = (_focusedDay.year - 2000) * 12 + (_focusedDay.month - 1);
    _pageController = PageController(initialPage: initialPage);
    _refreshRecords();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // DB에서 기록 다시 불러오기
  void _refreshRecords() {
    setState(() {
      _selectedRecordIds.clear();
      _recordsFuture = DatabaseHelper.instance.getAllRecords();
    });
  }

  // 날짜 비교용 헬퍼
  bool _isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  // 날짜 포맷 헬퍼 (YYYY-MM-DD HH:mm)
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // 미전송 항목 자동 선택 헬퍼 (나열형 전용)
  void _selectUnsyncedRecords(List<SquatRecord> records) {
    setState(() {
      _selectedRecordIds.clear();
      for (final r in records) {
        if (!r.isSynced && r.id != null) {
          _selectedRecordIds.add(r.id!);
        }
      }
    });
  }

  // 특정 기록 리스트 서버 전송 헬퍼
  Future<void> _sendRecordsListToServer(List<SquatRecord> recordsToSend) async {
    final targetRecords = recordsToSend.where((r) => r.id != null && !r.isSynced).toList();
    if (targetRecords.isEmpty) return;

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

    for (final record in targetRecords) {
      final response = await ApiService().sendSquatRecord(
        SquatWorkoutRequest.fromRecord(record),
      );
      if (response != null) {
        successCount++;
        if (record.id != null) {
          await DatabaseHelper.instance.updateSyncStatus(record.id!, true);
        }
      } else {
        failCount++;
      }
    }

    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      _refreshRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("☁️ 서버 전송 완료 (성공: ${successCount}건 / 실패: ${failCount}건)"),
        ),
      );
    }
  }

  // 체크박스로 선택된 기록 서버 다중 전송
  Future<void> _sendSelectedRecordsToServer(List<SquatRecord> allRecords) async {
    final selectedRecords = allRecords
        .where((r) => r.id != null && _selectedRecordIds.contains(r.id))
        .toList();

    if (selectedRecords.isEmpty) return;

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
        if (record.id != null) {
          await DatabaseHelper.instance.updateSyncStatus(record.id!, true);
        }
      } else {
        failCount++;
      }
    }

    if (context.mounted) Navigator.pop(context);

    if (context.mounted) {
      _refreshRecords();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("☁️ 서버 전송 완료 (성공: ${successCount}건 / 실패: ${failCount}건)"),
        ),
      );
    }
  }

  // 일자별 이벤트 맵 변환
  Map<DateTime, List<SquatRecord>> _groupRecordsByDate(List<SquatRecord> records) {
    final Map<DateTime, List<SquatRecord>> data = {};
    for (final r in records) {
      final dateKey = DateTime(r.date.year, r.date.month, r.date.day);
      data.putIfAbsent(dateKey, () => []).add(r);
    }
    return data;
  }

  // 상세 운동 리포트 바텀시트 팝업
  void _showDetailReportBottomSheet(BuildContext context, List<SquatRecord> records, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final dayRecords = records.where((r) => _isSameDay(r.date, date)).toList();

            // 해당 날짜 기록 중 선택된 아이템 계산
            final selectedInDay = dayRecords
                .where((r) => r.id != null && _selectedRecordIds.contains(r.id))
                .toList();
            final bool hasSelected = selectedInDay.isNotEmpty;

            return DraggableScrollableSheet(
              initialChildSize: 0.70,
              minChildSize: 0.4,
              maxChildSize: 0.90,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 드래그 핸들
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 헤더
                      Row(
                        children: [
                          const Icon(Icons.fitness_center_rounded, color: AppTheme.primarySky, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "${date.month}월 ${date.day}일 상세 리포트",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 바텀시트 전용 선택 백업 컨트롤 바
                      if (dayRecords.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setBottomSheetState(() {
                                    setState(() {
                                      for (final r in dayRecords) {
                                        if (!r.isSynced && r.id != null) {
                                          _selectedRecordIds.add(r.id!);
                                        }
                                      }
                                    });
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.playlist_add_check_rounded, size: 16, color: Color(0xFF334155)),
                                label: const Text(
                                  "미전송 항목 선택",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: hasSelected
                                    ? () async {
                                  await _sendSelectedRecordsToServer(dayRecords);
                                  setBottomSheetState(() {});
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primarySky,
                                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                icon: Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 16,
                                  color: hasSelected ? Colors.white : const Color(0xFF94A3B8),
                                ),
                                label: Text(
                                  "선택 (${selectedInDay.length})개 백업",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: hasSelected ? Colors.white : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),

                      // 리포트 상세 리스트
                      Expanded(
                        child: dayRecords.isEmpty
                            ? Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                "선택한 날짜에 저장된 스쿼트 기록이 없습니다.",
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: dayRecords.length,
                          itemBuilder: (context, index) {
                            return _buildRecordCard(dayRecords[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: FutureBuilder<List<SquatRecord>>(
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

            final rawRecords = snapshot.data ?? [];
            final records = List<SquatRecord>.from(rawRecords);
            records.sort((a, b) => _isAscending
                ? a.date.compareTo(b.date)
                : b.date.compareTo(a.date));

            final unsyncedCount = records.where((r) => !r.isSynced).length;
            final recordEvents = _groupRecordsByDate(records);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 상단 앱 헤더
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0),
                  child: _buildHeader(),
                ),
                const SizedBox(height: 20),

                // 2. 메인 컨텐츠 영역
                Expanded(
                  child: _isCalendarView
                      ? _buildCircleCalendarView(records, recordEvents, unsyncedCount)
                      : _buildListView(records, unsyncedCount),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 1. 상단 헤더
  Widget _buildHeader() {
    return SizedBox(
      height: 38,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              child: Icon(Icons.bar_chart_rounded, size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Records",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.add_chart_rounded, color: Colors.amber, size: 22),
              tooltip: "더미 데이터 생성",
              onPressed: () async {
                await DatabaseHelper.instance.insertDummyRecords();
                _refreshRecords();
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 22),
              onPressed: _refreshRecords,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. 컨트롤 바 (나열형 전용 미전송/선택 백업)
  Widget _buildControlBar(List<SquatRecord> records, int unsyncedCount) {
    final bool hasUnsynced = unsyncedCount > 0;
    final bool hasSelected = _selectedRecordIds.isNotEmpty;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: hasUnsynced ? () => _selectUnsyncedRecords(records) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasUnsynced ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_add_check_rounded,
                    size: 16,
                    color: hasUnsynced ? AppTheme.primarySky : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "미전송 $unsyncedCount",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasUnsynced ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: hasSelected ? () => _sendSelectedRecordsToServer(records) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: hasSelected ? AppTheme.primarySky : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: 16,
                    color: hasSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "선택 (${_selectedRecordIds.length})개 백업",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasSelected ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 3-A. 달력형 뷰
  Widget _buildCircleCalendarView(
      List<SquatRecord> records,
      Map<DateTime, List<SquatRecord>> eventMap,
      int unsyncedCount,
      ) {
    final selectedDayRecords = records
        .where((r) => _isSameDay(r.date, _selectedDay))
        .toList();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
        child: Container(
          padding: const EdgeInsets.all(20),
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
              // 1. 월 헤더
              _buildMonthHeader(),
              const SizedBox(height: 16),

              // 2. 요일 헤더
              _buildWeekDayHeader(),
              const SizedBox(height: 12),

              // 3. 달력 그리드
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (pageIndex) {
                    setState(() {
                      final year = 2000 + (pageIndex ~/ 12);
                      final month = (pageIndex % 12) + 1;
                      _focusedDay = DateTime(year, month, 1);
                    });
                  },
                  itemBuilder: (context, pageIndex) {
                    final monthDate = DateTime(
                      2000 + (pageIndex ~/ 12),
                      (pageIndex % 12) + 1,
                      1,
                    );
                    return _buildCircleGrid(eventMap, monthDate);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // 💡 4. 구분선 추가
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0), // 은은한 슬레이트 톤 경계선
              ),
              const SizedBox(height: 14),

              // 5. 운동 요약 리포트 카드 & 우측 2단 액션 버튼
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildDaySummaryCard(records, selectedDayRecords),
                    ),
                    const SizedBox(width: 8),
                    _buildRightActionButtons(records, selectedDayRecords),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 우측 2단 액션 버튼 (상단: 서버 백업 / 하단: 상세 보기 +)
  Widget _buildRightActionButtons(
      List<SquatRecord> allRecords,
      List<SquatRecord> selectedDayRecords,
      ) {
    final unsyncedInDay = selectedDayRecords.where((r) => !r.isSynced).toList();
    final bool hasUnsynced = unsyncedInDay.isNotEmpty;
    final bool hasRecords = selectedDayRecords.isNotEmpty;

    return SizedBox(
      width: 54,
      child: Column(
        children: [
          // 1. 상단: 서버 백업 버튼
          Expanded(
            child: Tooltip(
              message: hasUnsynced
                  ? "${_selectedDay.month}월 ${_selectedDay.day}일 미전송 ${unsyncedInDay.length}건 백업"
                  : "모든 기록 백업 완료",
              child: Material(
                color: hasUnsynced ? AppTheme.primarySky : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: hasUnsynced ? () => _sendRecordsListToServer(unsyncedInDay) : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Icon(
                      Icons.cloud_upload_rounded,
                      size: 20,
                      color: hasUnsynced ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 2. 하단: 상세 리포트 열기 (+) 버튼
          Expanded(
            child: Tooltip(
              message: "상세 리포트 보기",
              child: Material(
                color: hasRecords ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                // ❌ borderRadius: BorderRadius.circular(14), <- 이 줄을 삭제합니다.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14), // shape 내부의 borderRadius만 남겨둡니다.
                  side: BorderSide(
                    color: hasRecords ? AppTheme.primarySky : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  onTap: hasRecords
                      ? () => _showDetailReportBottomSheet(context, allRecords, _selectedDay)
                      : null,
                  borderRadius: BorderRadius.circular(14), // InkWell 터치 물결용 borderRadius는 유지
                  child: Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: hasRecords ? AppTheme.primarySky : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 월 선택 헤더 & 우측 '나열형 보기' 전환 버튼
  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "${_focusedDay.month}월",
          style: GoogleFonts.notoSansKr(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: const Color(0xFF0F172A),
          ),
        ),
        InkWell(
          onTap: () => setState(() => _isCalendarView = false),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primarySky.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.format_list_bulleted_rounded, size: 16, color: AppTheme.primarySky),
                SizedBox(width: 6),
                Text(
                  "나열형 보기",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primarySky,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 미니멀 요일 표시줄
  Widget _buildWeekDayHeader() {
    const days = ["일", "월", "화", "수", "목", "금", "토"];
    return Row(
      children: days.map((day) {
        final isSun = day == "일";
        final isSat = day == "토";
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSun
                    ? Colors.redAccent.withValues(alpha: 0.8)
                    : (isSat ? AppTheme.primarySky : const Color(0xFF94A3B8)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 수행한 세트 수에 따른 원(Circle) 배경색 반환 헬퍼
  Color _getCircleBgColor(int setCount, bool isSelected, bool isToday) {
    if (setCount == 0) {
      return isToday ? AppTheme.primarySky.withValues(alpha: 0.15) : Colors.white;
    }
    if (setCount == 1) return const Color(0xFFEFF6FF);
    if (setCount == 2) return const Color(0xFFBFDBFE);
    if (setCount == 3) return const Color(0xFF60A5FA);
    if (setCount == 4) return const Color(0xFF2563EB);
    return const Color(0xFF1E3A8A);
  }

  /// 스와이프용 그리드 렌더링 함수
  Widget _buildCircleGrid(
      Map<DateTime, List<SquatRecord>> eventMap,
      DateTime monthDate,
      ) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

    final startingOffset = firstDayOfMonth.weekday % 7;
    final totalCells = startingOffset + daysInMonth;
    final totalRows = (totalCells / 7).ceil(); // 해당 월의 행(주) 수 계산

    return LayoutBuilder(
      builder: (context, constraints) {
        // 💡 현재 뷰가 가진 높이/너비를 기반으로 동적 childAspectRatio 계산
        final double itemWidth = constraints.maxWidth / 7;
        final double itemHeight = constraints.maxHeight / totalRows;
        final double dynamicAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: dynamicAspectRatio, // 동적 비율 적용
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
          ),
          itemBuilder: (context, index) {
            if (index < startingOffset) {
              return const SizedBox.shrink();
            }

            final dayNum = index - startingOffset + 1;
            final cellDate = DateTime(monthDate.year, monthDate.month, dayNum);
            final isSelected = _isSameDay(cellDate, _selectedDay);
            final isToday = _isSameDay(cellDate, DateTime.now());

            final normalizedKey = DateTime(cellDate.year, cellDate.month, cellDate.day);
            final events = eventMap[normalizedKey] ?? [];
            final setCount = events.length;

            final bgColor = _getCircleBgColor(setCount, isSelected, isToday);

            final isDarkBg = setCount >= 3;
            final textColor = isDarkBg
                ? Colors.white
                : (cellDate.weekday == DateTime.sunday
                ? Colors.redAccent
                : const Color(0xFF0F172A));

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = cellDate;
                });
              },
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                    border: isSelected
                        ? Border.all(color: AppTheme.accentGreen, width: 2.5)
                        : (isToday
                        ? Border.all(color: AppTheme.primarySky, width: 2.0)
                        : null),
                    boxShadow: isSelected || setCount > 0
                        ? [
                      BoxShadow(
                        color: (isSelected ? AppTheme.accentGreen : bgColor).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 3-B. 나열형 뷰
  Widget _buildListView(List<SquatRecord> records, int unsyncedCount) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "전체 운동 기록 목록",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _isCalendarView = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySky.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.primarySky),
                        SizedBox(width: 6),
                        Text(
                          "달력형 보기",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primarySky,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildControlBar(records, unsyncedCount),
            const SizedBox(height: 16),

            Expanded(
              child: records.isEmpty
                  ? _buildEmptyView()
                  : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return _buildRecordCard(records[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 자세 오류 태그 칩 빌더
  Widget _buildErrorChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

  /// 개별 기록 카드
  Widget _buildRecordCard(SquatRecord record) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (record.id != null) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _selectedRecordIds.contains(record.id),
                            activeColor: AppTheme.primarySky,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
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
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.primarySky),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatDate(record.date),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: record.isSynced ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: record.isSynced ? Colors.green : Colors.grey.shade400,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          record.isSynced ? "백업됨" : "미전송",
                          style: TextStyle(
                            fontSize: 10,
                            color: record.isSynced ? Colors.green.shade800 : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    onPressed: () async {
                      if (record.id == null) return;

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("기록 삭제"),
                          content: Text(
                            record.isSynced
                                ? "서버에 백업된 기록입니다. 서버 DB와 로컬 기록이 모두 삭제됩니다."
                                : "이 기록을 로컬 DB에서 삭제하시겠습니까?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("취소"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("삭제", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      if (record.isSynced) {
                        final serverDeleted = await ApiService().deleteSquatRecordByUuid(record.uuid);
                        if (!serverDeleted) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("❌ 서버 기록 삭제에 실패했습니다.")),
                            );
                          }
                          return;
                        }
                      }

                      await DatabaseHelper.instance.deleteRecord(record.id!);
                      _refreshRecords();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("🗑️ 해당 기록이 삭제되었습니다.")),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 12),

            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 22),
                const SizedBox(width: 8),
                Text(
                  "성공 횟수: ${record.successCount}회",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

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
  }

  /// 데이터 없음 빈 화면
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            "저장된 스쿼트 기록이 없습니다.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  /// 선택된 날짜의 일일 운동 요약 카드 위젯
  Widget _buildDaySummaryCard(List<SquatRecord> allRecords, List<SquatRecord> selectedDayRecords) {
    final totalSuccess = selectedDayRecords.fold<int>(0, (sum, r) => sum + r.successCount);
    final totalErrors = selectedDayRecords.fold<int>(
      0,
          (sum, r) => sum + r.waistErrorCount + r.depthErrorCount + r.goodMorningCount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, color: AppTheme.primarySky, size: 20),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    // 1. 날짜 수치 영역 (Anton 적용)
                    TextSpan(
                      text: "${_selectedDay.month}/${_selectedDay.day}",
                      style: GoogleFonts.anton(
                        fontSize: 16,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    // 2. 한글 문구 영역 (DM Sans 적용)
                    TextSpan(
                      text: " 운동 요약",
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 14),

          if (selectedDayRecords.isEmpty)
          // 💡 수치 Row와 동일한 높이(38px) 및 중앙 정렬을 부여하여 레이아웃 변형 방지
            Container(
              height: 38,
              alignment: Alignment.center,
              child: const Text(
                "해당 일자에 운동 기록이 없습니다.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Row(
              children: [
                _buildStatItem("$totalSuccess회", AppTheme.accentGreen),
                const SizedBox(width: 4),
                _buildStatItem("${selectedDayRecords.length}세트", AppTheme.primarySky),
                const SizedBox(width: 4),
                _buildStatItem("$totalErrors회", Colors.orange),
              ],
            ),
        ],
      ),
    );
  }

  /// 요약 카드 수치 항목 빌더 (1:1:1 균등 비율 + 안전 축소)
  Widget _buildStatItem(String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.anton(
                fontSize: 15,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

}