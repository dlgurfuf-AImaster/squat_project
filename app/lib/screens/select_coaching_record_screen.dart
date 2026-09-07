import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/coaching_provider.dart';
import '../theme/app_theme.dart';

class SelectCoachingRecordScreen extends StatefulWidget {
  const SelectCoachingRecordScreen({super.key});

  @override
  State<SelectCoachingRecordScreen> createState() => _SelectCoachingRecordScreenState();
}

class _SelectCoachingRecordScreenState extends State<SelectCoachingRecordScreen> {
  // 코칭용으로 선택된 서버 단일 기록 (dynamic / ServerRecord 타입)
  dynamic _selectedRecord;

  // UI 상태 관리 (달력형 / 나열형)
  bool _isCalendarView = true;
  bool _isMonthPickerOpen = false;
  DateTime _selectedMonth = DateTime.now();

  // 캘린더 기준 날짜 및 PageController 상태
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialPage = (_focusedDay.year - 2000) * 12 + (_focusedDay.month - 1);
    _pageController = PageController(initialPage: initialPage);

    // 화면 진입 시 서버 DB 기록 목록 자동 로드
    _refreshRecords();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _refreshRecords() {
    Future.microtask(() {
      if (mounted) {
        Provider.of<CoachingProvider>(context, listen: false).fetchServerRecords();
      }
    });
  }

  // 서버 record 객체에서 DateTime 안전 추출 (String 또는 DateTime 대응)
  DateTime _getRecordDate(dynamic record) {
    if (record == null) return DateTime.now();
    try {
      if (record.date is DateTime) return record.date;
    } catch (_) {}
    try {
      final timeVal = record.recordTime;
      if (timeVal is DateTime) return timeVal;
      if (timeVal is String) {
        return DateTime.tryParse(timeVal) ?? DateTime.now();
      }
    } catch (_) {}
    return DateTime.now();
  }

  bool _isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Map<DateTime, List<dynamic>> _groupRecordsByDate(List<dynamic> records) {
    final Map<DateTime, List<dynamic>> data = {};
    for (final r in records) {
      final recordDate = _getRecordDate(r);
      final dateKey = DateTime(recordDate.year, recordDate.month, recordDate.day);
      data.putIfAbsent(dateKey, () => []).add(r);
    }
    return data;
  }

  // 선택 완료 및 이전 화면으로 선택한 기록의 UUID(Set<String>) 전달
  void _confirmSelection(dynamic record) {
    if (record != null && record.uuid != null) {
      // CoachingScreen이 요구하는 Set<String> 타입에 맞춰 전달
      Navigator.pop(context, <String>{record.uuid.toString()});
    } else {
      Navigator.pop(context);
    }
  }

  // 상세 운동 기록 바텀시트 팝업 (코칭 선택 전용)
  void _showDetailReportBottomSheet(
      BuildContext context, List<dynamic> records, DateTime date) {
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
            final dayRecords = records
                .where((r) => _isSameDay(_getRecordDate(r), date))
                .toList()
              ..sort((a, b) => _getRecordDate(b).compareTo(_getRecordDate(a)));

            final totalSuccess = dayRecords.fold<int>(0, (sum, r) => sum + (r.successCount as int));
            final totalWaist = dayRecords.fold<int>(0, (sum, r) => sum + (r.waistErrorCount as int));
            final totalDepth = dayRecords.fold<int>(0, (sum, r) => sum + (r.depthErrorCount as int));
            final totalGoodMorning = dayRecords.fold<int>(0, (sum, r) => sum + (r.goodMorningCount as int));
            final totalErrors = totalWaist + totalDepth + totalGoodMorning;

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
                          const Icon(Icons.psychology_rounded, color: AppTheme.primarySky, size: 22),
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
                                  text: " 세트 선택",
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
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),

                      // 3. 세트별 상세 기록 리스트
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
                            final isSelected = _selectedRecord?.uuid == record.uuid;
                            return _buildSelectableRecordCard(
                              record,
                              isSelected: isSelected,
                              showFullDate: false,
                              onSelect: () {
                                setState(() {
                                  _selectedRecord = record;
                                });
                                Navigator.pop(context);
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
        child: Consumer<CoachingProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "서버에서 스쿼트 기록을 불러오는 중...",
                      style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            if (provider.errorMessage != null && provider.serverRecords.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "❌ ${provider.errorMessage}",
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshRecords,
                      child: const Text("다시 시도"),
                    ),
                  ],
                ),
              );
            }

            final rawRecords = provider.serverRecords;
            final records = List<dynamic>.from(rawRecords)
              ..sort((a, b) => _getRecordDate(b).compareTo(_getRecordDate(a)));

            final recordEvents = _groupRecordsByDate(records);

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 24.0, top: 16.0),
                      child: _buildHeader(),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isCalendarView
                          ? _buildCircleCalendarView(records, recordEvents)
                          : _buildListView(records),
                    ),
                    if (_selectedRecord != null) const SizedBox(height: 80),
                  ],
                ),

                // 하단 확정 플로팅 바
                if (_selectedRecord != null)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 20,
                    child: _buildBottomConfirmButton(),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 14),
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
            child: Icon(Icons.psychology_rounded, size: 22, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Server Record",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              "서버에 저장된 기록 중 분석할 데이터 선택",
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const Spacer(),
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
    );
  }

  /// 2. 컨트롤 바 (나열형 전용)
  Widget _buildControlBar() {
    return Row(
      children: [
        if (_isMonthPickerOpen)
          Expanded(child: _buildMorphingMonthPicker())
        else
          _buildMorphingMonthPicker(),
      ],
    );
  }

  /// 3-A. 달력형 뷰 (하단 디테일 스크롤 리스트 직접 노출)
  Widget _buildCircleCalendarView(
      List<dynamic> records,
      Map<DateTime, List<dynamic>> eventMap,
      ) {
    // 선택된 날짜의 세트 기록 필터링 및 최신순 정렬
    final selectedDayRecords = records
        .where((r) => _isSameDay(_getRecordDate(r), _selectedDay))
        .toList()
      ..sort((a, b) => _getRecordDate(b).compareTo(_getRecordDate(a)));

    // 일일 통계 집계
    final totalSuccess = selectedDayRecords.fold<int>(0, (sum, r) => sum + (r.successCount as int? ?? 0));
    final totalWaist = selectedDayRecords.fold<int>(0, (sum, r) => sum + (r.waistErrorCount as int? ?? 0));
    final totalDepth = selectedDayRecords.fold<int>(0, (sum, r) => sum + (r.depthErrorCount as int? ?? 0));
    final totalGoodMorning = selectedDayRecords.fold<int>(0, (sum, r) => sum + (r.goodMorningCount as int? ?? 0));
    final totalErrors = totalWaist + totalDepth + totalGoodMorning;

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
      child: Column(
        children: [
          // 1. 컴팩트 달력 영역
          Container(
            padding: const EdgeInsets.all(16),
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(),
                const SizedBox(height: 12),
                _buildWeekDayHeader(),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
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
          const SizedBox(height: 14),

          // 2. 디테일 기록 카드 & 스크롤 리스트 영역
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 32, 64, 0.04),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 날짜 및 총 세트 수 헤더
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
                                fontSize: 18,
                                color: const Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextSpan(
                              text: " 세트 상세 기록",
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (selectedDayRecords.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySky.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "총 ${selectedDayRecords.length}세트",
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primarySky,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 운동 기록이 있을 경우 일일 요약 통계 뱃지 바 표시
                  if (selectedDayRecords.isNotEmpty) ...[
                    Row(
                      children: [
                        _buildSummaryStatBox("성공", "$totalSuccess회", AppTheme.accentGreen),
                        const SizedBox(width: 6),
                        _buildSummaryStatBox("세트", "${selectedDayRecords.length}세트", AppTheme.primarySky),
                        const SizedBox(width: 6),
                        _buildSummaryStatBox("자세 오차", "$totalErrors회", Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                  ],

                  // 세트별 스크롤 가능 리스트
                  Expanded(
                    child: selectedDayRecords.isEmpty
                        ? const Center(
                      child: Text(
                        "선택한 날짜에 저장된 스쿼트 기록이 없습니다.",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: selectedDayRecords.length,
                      itemBuilder: (context, index) {
                        final record = selectedDayRecords[index];
                        final isSelected = _selectedRecord?.uuid == record.uuid;
                        return _buildSelectableRecordCard(
                          record,
                          isSelected: isSelected,
                          showFullDate: false,
                          onSelect: () {
                            setState(() {
                              _selectedRecord = record;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailReportButton(
      List<dynamic> allRecords,
      List<dynamic> selectedDayRecords,
      ) {
    final bool hasRecords = selectedDayRecords.isNotEmpty;

    return Tooltip(
      message: "세트 목록 보기",
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
                size: 24,
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
      Map<DateTime, List<dynamic>> eventMap,
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
  Widget _buildListView(List<dynamic> records) {
    final monthlyRecords = records.where((r) {
      final date = _getRecordDate(r);
      return date.year == _selectedMonth.year && date.month == _selectedMonth.month;
    }).toList();

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
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
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
                            text: "월 서버 운동 기록",
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
            _buildControlBar(),
            const SizedBox(height: 16),
            Expanded(
              child: monthlyRecords.isEmpty
                  ? _buildEmptyView()
                  : ListView.builder(
                itemCount: monthlyRecords.length,
                itemBuilder: (context, index) {
                  final record = monthlyRecords[index];
                  final isSelected = _selectedRecord?.uuid == record.uuid;
                  return _buildSelectableRecordCard(
                    record,
                    isSelected: isSelected,
                    showFullDate: true,
                    onSelect: () {
                      setState(() {
                        _selectedRecord = record;
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

  /// 선택 전용 개별 세트 기록 카드 빌더
  Widget _buildSelectableRecordCard(
      dynamic record, {
        required bool isSelected,
        bool showFullDate = false,
        required VoidCallback onSelect,
      }) {
    const Color successColor = Color(0xFF10B981);
    const Color waistColor = Color(0xFFF59E0B);
    const Color depthColor = Color(0xFFF97316);
    const Color morningColor = Color(0xFFEF4444);

    final int successCount = record.successCount ?? 0;
    final int waistErrorCount = record.waistErrorCount ?? 0;
    final int depthErrorCount = record.depthErrorCount ?? 0;
    final int goodMorningCount = record.goodMorningCount ?? 0;

    final int totalCount = successCount + waistErrorCount + depthErrorCount + goodMorningCount;
    final DateTime recordDate = _getRecordDate(record);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primarySky.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.primarySky : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primarySky.withValues(alpha: 0.15)
                  : const Color.fromRGBO(23, 32, 64, 0.04),
              blurRadius: isSelected ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? AppTheme.primarySky : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    showFullDate ? _formatFullDate(recordDate) : _formatTime(recordDate),
                    style: GoogleFonts.dmSans(
                      fontSize: showFullDate ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
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
                  _buildRecordStatBadge("정상", "${successCount}회", successColor),
                  const SizedBox(width: 4),
                  _buildRecordStatBadge("허리과숙임", "${waistErrorCount}회", waistColor),
                  const SizedBox(width: 4),
                  _buildRecordStatBadge("얕은깊이", "${depthErrorCount}회", depthColor),
                  const SizedBox(width: 4),
                  _buildRecordStatBadge("상체선행", "${goodMorningCount}회", morningColor),
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            "서버에 저장된 스쿼트 기록이 없습니다.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummaryCard(
      List<dynamic> allRecords,
      List<dynamic> selectedDayRecords,
      ) {
    final totalSuccess = selectedDayRecords.fold<int>(0, (sum, r) => sum + (r.successCount as int));
    final totalErrors = selectedDayRecords.fold<int>(
      0,
          (sum, r) =>
      sum +
          (r.waistErrorCount as int) +
          (r.depthErrorCount as int) +
          (r.goodMorningCount as int),
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
        secondChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

  /// 4. 하단 선택 확정 플로팅 버튼
  Widget _buildBottomConfirmButton() {
    final record = _selectedRecord!;
    final recordDate = _getRecordDate(record);
    final totalCount = (record.successCount as int? ?? 0) +
        (record.waistErrorCount as int? ?? 0) +
        (record.depthErrorCount as int? ?? 0) +
        (record.goodMorningCount as int? ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.3),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatFullDate(recordDate),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "총 $totalCount회 수행 기록 선택됨",
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _confirmSelection(record),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primarySky,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Row(
              children: [
                Text(
                  "선택 완료",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}