import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dtos/squat_workout_request.dart';
import '../models/squat_record.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
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
  bool _isAscending = false; // (false: 최신순, true: 과거순)
  bool _isMonthPickerOpen = false; // <-- 인라인 월 피커 열림 상태 변수 추가
  DateTime _selectedMonth = DateTime.now(); // 월별 필터링용 날짜

  // 캘린더 기준 날짜 및 PageController 상태
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
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

  // 서버 전송 통합 메서드 (선택된 항목 또는 지정 리스트 전송)
  Future<void> _sendRecordsToServer(List<SquatRecord> recordsToSend) async {
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

    if (!mounted) return;
    Navigator.pop(context); // 로딩 다이얼로그 닫기

    _refreshRecords();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("☁️ 서버 전송 완료 (성공: $successCount건 / 실패: $failCount건)"),
      ),
    );
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
  void _showDetailReportBottomSheet(
      BuildContext context, List<SquatRecord> records, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            final dayRecords = records.where((r) => _isSameDay(r.date, date)).toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            final totalSuccess = dayRecords.fold<int>(0, (sum, r) => sum + r.successCount);
            final totalWaist = dayRecords.fold<int>(0, (sum, r) => sum + r.waistErrorCount);
            final totalDepth = dayRecords.fold<int>(0, (sum, r) => sum + r.depthErrorCount);
            final totalGoodMorning = dayRecords.fold<int>(0, (sum, r) => sum + r.goodMorningCount);
            final totalErrors = totalWaist + totalDepth + totalGoodMorning;

            final selectedInDay = dayRecords
                .where((r) => r.id != null && _selectedRecordIds.contains(r.id))
                .toList();
            final bool hasSelected = selectedInDay.isNotEmpty;

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      // 1. 헤더
                      Row(
                        children: [
                          const Icon(Icons.bar_chart_rounded, color: AppTheme.primarySky, size: 22),
                          const SizedBox(width: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "${date.month}/${date.day}",
                                  style: GoogleFonts.anton(
                                    fontSize: 18,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: " 상세 리포트",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
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

                      // 2. 요약 카드
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(23, 32, 64, 0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "일일 운동 요약",
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildSummaryStatBox("성공", "$totalSuccess회", AppTheme.accentGreen),
                                const SizedBox(width: 6),
                                _buildSummaryStatBox("세트", "${dayRecords.length}세트", AppTheme.primarySky),
                                const SizedBox(width: 6),
                                _buildSummaryStatBox("자세 오차", "$totalErrors회", Colors.orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. 백업 컨트롤 바
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
                                  "전체 선택",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: hasSelected
                                    ? () async {
                                  await _sendRecordsToServer(selectedInDay);
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
                                  "서버 (${selectedInDay.length})세트 전송",
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

                      // 4. 세트별 상세 기록 리스트
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
                            final record = dayRecords[index];
                            return _buildRecordCard(
                              record,
                              showFullDate: false,
                              onTap: () {
                                setBottomSheetState(() {
                                  setState(() {
                                    if (_selectedRecordIds.contains(record.id)) {
                                      _selectedRecordIds.remove(record.id);
                                    } else if (record.id != null) {
                                      _selectedRecordIds.add(record.id!);
                                    }
                                  });
                                });
                              },
                            );
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
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0),
                  child: _buildHeader(),
                ),
                const SizedBox(height: 20),
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

  /// 2. 컨트롤 바 (나열형 전용)
  Widget _buildControlBar(List<SquatRecord> records, int unsyncedCount) {
    final bool hasUnsynced = unsyncedCount > 0;
    final bool hasSelected = _selectedRecordIds.isNotEmpty;

    final selectedRecords = records
        .where((r) => r.id != null && _selectedRecordIds.contains(r.id))
        .toList();

    return Row(
      children: [
        // 1. 기존 InkWell 대신 모핑 피커 적용 (열렸을 땐 Expanded로 전체 너비 확보)
        if (_isMonthPickerOpen)
          Expanded(child: _buildMorphingMonthPicker())
        else
          _buildMorphingMonthPicker(),

        // 2. 피커가 닫혀있을 때만 [전체], [세트 전송] 버튼 표시
        if (!_isMonthPickerOpen) ...[
          const SizedBox(width: 8),
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
                      "전체",
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
              onTap: hasSelected ? () => _sendRecordsToServer(selectedRecords) : null,
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
                      "(${selectedRecords.length})세트 전송",
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

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
      child: Column(
        children: [
          Expanded(
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
                  _buildMonthHeader(),
                  const SizedBox(height: 16),
                  _buildWeekDayHeader(),
                  const SizedBox(height: 12),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildDaySummaryCard(records, selectedDayRecords),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildServerBackupButton(records, selectedDayRecords),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: _buildDetailReportButton(records, selectedDayRecords),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerBackupButton(
      List<SquatRecord> allRecords,
      List<SquatRecord> selectedDayRecords,
      ) {
    final unsyncedInDay = selectedDayRecords.where((r) => !r.isSynced).toList();
    final bool hasUnsynced = unsyncedInDay.isNotEmpty;

    return Tooltip(
      message: hasUnsynced
          ? "${_selectedDay.month}월 ${_selectedDay.day}일 미전송 ${unsyncedInDay.length}건 백업"
          : "모든 기록 백업 완료",
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: hasUnsynced ? AppTheme.primarySky : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          boxShadow: hasUnsynced
              ? [
            BoxShadow(
              color: AppTheme.primarySky.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: hasUnsynced ? () => _sendRecordsToServer(unsyncedInDay) : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
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
    );
  }

  Widget _buildDetailReportButton(
      List<SquatRecord> allRecords,
      List<SquatRecord> selectedDayRecords,
      ) {
    final bool hasRecords = selectedDayRecords.isNotEmpty;

    return Tooltip(
      message: "상세 리포트 보기",
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: hasRecords ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasRecords ? AppTheme.primarySky : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: hasRecords
              ? [
            BoxShadow(
              color: AppTheme.primarySky.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: hasRecords
                ? () => _showDetailReportBottomSheet(context, allRecords, _selectedDay)
                : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: AppTheme.primarySky.withValues(alpha: 0.15),
            highlightColor: AppTheme.primarySky.withValues(alpha: 0.08),
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
    );
  }

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

  Widget _buildCircleGrid(
      Map<DateTime, List<SquatRecord>> eventMap,
      DateTime monthDate,
      ) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;

    final startingOffset = firstDayOfMonth.weekday % 7;
    final totalCells = startingOffset + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = constraints.maxWidth / 7;
        final double itemHeight = constraints.maxHeight / totalRows;
        final double dynamicAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: dynamicAspectRatio,
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
                        color: (isSelected ? AppTheme.accentGreen : bgColor)
                            .withValues(alpha: 0.3),
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
    // 선택한 월의 기록만 필터링
    final monthlyRecords = records
        .where((r) =>
    r.date.year == _selectedMonth.year &&
        r.date.month == _selectedMonth.month)
        .toList();
    final monthlyUnsyncedCount =
        monthlyRecords.where((r) => !r.isSynced).length;

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
                // 👇 이 영역을 새로 구성했습니다 (기록 아이콘 + Anton/dmSans 조합)
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded, // 기록 아이콘 (취향에 따라 Icons.receipt_long_rounded 등으로 변경 가능)
                      color: AppTheme.primarySky,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "${_selectedMonth.month}",
                            style: GoogleFonts.anton(
                              fontSize: 20,
                              color: const Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextSpan(
                            text: "월 운동 기록",
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 우측 '달력형 보기' 버튼 (기존 동일)
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
            _buildControlBar(monthlyRecords, monthlyUnsyncedCount),

            const SizedBox(height: 16),
            Expanded(
              child: monthlyRecords.isEmpty
                  ? _buildEmptyView()
                  : ListView.builder(
                itemCount: monthlyRecords.length,
                itemBuilder: (context, index) {
                  final record = monthlyRecords[index];
                  return _buildRecordCard(
                    record,
                    showFullDate: true,
                    onTap: () {
                      setState(() {
                        if (_selectedRecordIds.contains(record.id)) {
                          _selectedRecordIds.remove(record.id);
                        } else if (record.id != null) {
                          _selectedRecordIds.add(record.id!);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개별 세트 기록 카드 빌더
  Widget _buildRecordCard(
      SquatRecord record, {
        bool showFullDate = false,
        VoidCallback? onTap,
      }) {
    final bool isSelected = record.id != null && _selectedRecordIds.contains(record.id);
    final bool isSelectable = !record.isSynced && record.id != null;

    const Color successColor = Color(0xFF10B981);
    const Color waistColor = Color(0xFFF59E0B);
    const Color depthColor = Color(0xFFF97316);
    const Color morningColor = Color(0xFFEF4444);

    final int totalCount = record.successCount +
        record.waistErrorCount +
        record.depthErrorCount +
        record.goodMorningCount;

    return GestureDetector(
      onTap: isSelectable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.primarySky : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(23, 32, 64, 0.04),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  if (isSelectable)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: isSelected,
                          activeColor: AppTheme.primarySky,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (_) => onTap?.call(),
                        ),
                      ),
                    ),
                  Icon(Icons.access_time_rounded, size: 14, color: const Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    showFullDate ? _formatFullDate(record.date) : _formatTime(record.date),
                    style: GoogleFonts.dmSans(
                      fontSize: showFullDate ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSyncChip(record.isSynced),
                  const Spacer(),
                  Text(
                    "$totalCount",
                    style: GoogleFonts.anton(
                      fontSize: 22,
                      color: AppTheme.primarySky,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    "회",
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildRecordStatBadge("정상", "${record.successCount}회", successColor),
                  const SizedBox(width: 4),
                  _buildRecordStatBadge("허리과숙임", "${record.waistErrorCount}회", waistColor),
                  const SizedBox(width: 4),
                  _buildRecordStatBadge("얕은깊이", "${record.depthErrorCount}회", depthColor),
                  const SizedBox(width: 4),
                  _buildRecordStatBadge("상체선행", "${record.goodMorningCount}회", morningColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$year.$month.$day ($hour:$minute)";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Widget _buildRecordStatBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: GoogleFonts.anton(
                  fontSize: 14,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncChip(bool isSynced) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSynced ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSynced ? const Color(0xFFA7F3D0) : const Color(0xFFFFEDD5),
        ),
      ),
      child: Text(
        isSynced ? "전송됨" : "전송 가능",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSynced ? const Color(0xFF059669) : const Color(0xFFEA580C),
        ),
      ),
    );
  }

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

  Widget _buildDaySummaryCard(
      List<SquatRecord> allRecords,
      List<SquatRecord> selectedDayRecords,
      ) {
    final totalSuccess = selectedDayRecords.fold<int>(0, (sum, r) => sum + r.successCount);
    final totalErrors = selectedDayRecords.fold<int>(
      0,
          (sum, r) => sum + r.waistErrorCount + r.depthErrorCount + r.goodMorningCount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 64, 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                    TextSpan(
                      text: "${_selectedDay.month}/${_selectedDay.day}",
                      style: GoogleFonts.anton(
                        fontSize: 16,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
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

  Widget _buildSummaryStatBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: GoogleFonts.anton(
                  fontSize: 16,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorphingMonthPicker() {
    final List<int> months = List.generate(12, (i) => i + 1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      // 닫혀있을 때는 작은 버튼 크기, 열리면 전체 너비로 확장
      width: _isMonthPickerOpen ? double.infinity : 90,
      padding: EdgeInsets.all(_isMonthPickerOpen ? 16 : 0),
      decoration: BoxDecoration(
        color: _isMonthPickerOpen
            ? const Color(0xFFF8FAFC)
            : AppTheme.primarySky.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(_isMonthPickerOpen ? 20 : 12),
        border: Border.all(
          color: _isMonthPickerOpen
              ? AppTheme.primarySky.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: _isMonthPickerOpen
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,

        // ① 닫혀있을 때: 접혀있는 월 버튼
        firstChild: InkWell(
          onTap: () => setState(() => _isMonthPickerOpen = true),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${_selectedMonth.month}월",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primarySky,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppTheme.primarySky,
                ),
              ],
            ),
          ),
        ),

        // ② 열려있을 때: 연도 조절 + 월 선택 다이얼 (CupertinoPicker)
        secondChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단: 연도 선택 & 접기 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year - 1, _selectedMonth.month);
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "${_selectedMonth.year}년",
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_right_rounded, size: 22),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year + 1, _selectedMonth.month);
                        });
                      },
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _isMonthPickerOpen = false),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFE2E8F0)),

            // 월 선택 다이얼 (CupertinoPicker)
            SizedBox(
              height: 120,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: _selectedMonth.month - 1,
                ),
                itemExtent: 38,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      index + 1,
                    );
                  });
                },
                children: months
                    .map((m) => Center(
                  child: Text(
                    "$m월",
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}