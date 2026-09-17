import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../dtos/aggregate_coaching_request.dart';
import '../dtos/coaching_response.dart';
import '../providers/coaching_provider.dart';
import '../theme/app_theme.dart';
import 'select_coaching_record_screen.dart';

/// AI 코칭 화면
class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen> {
  /// 선택된 서버 기록 UUID 집합
  final Set<String> _selectedServerUuids = {};

  @override
  void initState() {
    super.initState();
    // 화면 빌드 후 초기 서버 기록 페치
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CoachingProvider>().fetchServerRecords();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Shared Event Handlers
  // ---------------------------------------------------------------------------

  /// 서버 기록 선택 화면으로 이동 및 선택 결과 반영
  Future<void> _handleSelectHistory() async {
    final selected = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectCoachingRecordScreen(),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedServerUuids.clear();
        _selectedServerUuids.addAll(selected);
      });
    }
  }

  /// AI 코칭 분석 요청 (단일/통합 자동 분기)
  Future<void> _handleRequestCoaching(CoachingProvider provider) async {
    if (_selectedServerUuids.isEmpty) return; // 방어적 예외 처리

    final selectedList = _selectedServerUuids.toList();
    setState(() {
      _selectedServerUuids.clear();
    });

    if (selectedList.length == 1) {
      await provider.requestSingleCoaching(selectedList.first);
    } else {
      await provider.requestAggregateCoaching(
        AggregateCoachingRequest.byUuids(selectedList),
      );
    }
  }

  /// 코칭 상태 초기화 및 선택 해제
  void _handleReset(CoachingProvider provider) {
    provider.resetCoaching();
    setState(() {
      _selectedServerUuids.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        body: SafeArea(
          child: Consumer<CoachingProvider>(
            builder: (context, provider, child) {
              final coaching = provider.latestCoaching;
              final errorMessage = provider.errorMessage;
              final isAiAnalyzing = provider.isAiAnalyzing;
              final isFetching = provider.isFetching;

              return Column(
                children: [
                  // 1. [상단 헤더 영역]
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _HeaderView(),
                        _ResetButton(
                          isFetching: isFetching,
                          isDisabled: isFetching || isAiAnalyzing,
                          onTap: () => _handleReset(provider),
                        ),
                      ],
                    ),
                  ),

                  // 2. [메인 콘텐츠 영역 - 상태별 스위칭]
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: isAiAnalyzing
                          ? const AiAnalysisFullScreenLoading(key: ValueKey('ai_loading'))
                          : coaching != null
                          ? StaggeredResultContentView(
                        key: ValueKey('result_${coaching.hashCode}'),
                        coaching: coaching,
                        selectedUuids: _selectedServerUuids,
                        isFetching: isFetching,
                        onSelectHistory: _handleSelectHistory,
                        onRequestCoaching: () => _handleRequestCoaching(provider),
                      )
                          : ListView(
                        key: const ValueKey('normal_screen'),
                        padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
                        children: [
                          if (errorMessage != null)
                            _buildErrorCard(errorMessage)
                          else
                            _buildPlaceholderCard(_selectedServerUuids.length),
                          const SizedBox(height: 20),
                          _ActionButtons(
                            isFetching: isFetching,
                            selectedUuids: _selectedServerUuids,
                            onSelectHistory: _handleSelectHistory,
                            onRequestCoaching: () => _handleRequestCoaching(provider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(int selectedCount) {
    return AiCoachingSloganBanner(
      child: AIHeroPlaceholder(selectedCount: selectedCount),
    );
  }

  Widget _buildErrorCard(String error) {
    return AiCoachingSloganBanner(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Header & Reset Button Widgets
// =============================================================================

/// 상단 앱 제목 및 아이콘 헤더
class _HeaderView extends StatelessWidget {
  const _HeaderView();

  @override
  Widget build(BuildContext context) {
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
              Icons.auto_awesome_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "AI Coaching",
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
}

/// 우측 상단 초기화 버튼
class _ResetButton extends StatelessWidget {
  final bool isFetching;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ResetButton({
    required this.isFetching,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (isFetching)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF64748B),
                ),
              )
            else
              const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              isFetching ? "초기화 중" : "초기화",
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Action Buttons Component
// =============================================================================

/// 하단 메인 액션 버튼 모듈 (기록 보기 + AI 분석 요청 호흡 애니메이션 적용)
class _ActionButtons extends StatefulWidget {
  final bool isFetching;
  final Set<String> selectedUuids;
  final VoidCallback onSelectHistory;
  final VoidCallback onRequestCoaching;

  const _ActionButtons({
    required this.isFetching,
    required this.selectedUuids,
    required this.onSelectHistory,
    required this.onRequestCoaching,
  });

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    // 호흡 주기 애니메이션 (1.2초 간격 무한 반복)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _breathAnimation = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.selectedUuids.isNotEmpty && !widget.isFetching;

    return Row(
      children: [
        // 1. 좌측 버튼: 서버 기록 보기
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.primarySky,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primarySky.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: widget.onSelectHistory,
                borderRadius: BorderRadius.circular(18),
                splashColor: AppTheme.primarySky.withValues(alpha: 0.15),
                highlightColor: AppTheme.primarySky.withValues(alpha: 0.08),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: AppTheme.primarySky,
                      ),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "서버 기록 보기",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primarySky,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // 2. 우측 버튼: AI 분석 요청 (그림자 호흡 애니메이션 적용)
        Expanded(
          child: AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              final double breathValue = _breathAnimation.value;

              return Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: isEnabled
                      ? const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  )
                      : null,
                  color: isEnabled ? null : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isEnabled
                      ? [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(
                        alpha: 0.18 + (breathValue * 0.32),
                      ),
                      blurRadius: 4 + (breathValue * 6),
                      spreadRadius: 0.5 + (breathValue * 1.5),
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0369A1).withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : [],
                ),
                padding: EdgeInsets.all(isEnabled ? 2.0 : 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isEnabled
                        ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Color(0xFFF8FAFC),
                      ],
                    )
                        : null,
                    color: isEnabled ? null : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(isEnabled ? 16.0 : 18),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isEnabled ? widget.onRequestCoaching : null,
                      borderRadius: BorderRadius.circular(isEnabled ? 16.0 : 18),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: isEnabled
                                  ? const Color(0xFF0284C7).withValues(
                                  alpha: 0.75 + (breathValue * 0.25))
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.selectedUuids.isNotEmpty
                                    ? "AI 분석 요청 (${widget.selectedUuids.length})"
                                    : "AI 분석 요청",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isEnabled
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// StaggeredResultContentView
// =============================================================================

/// AI 분석 결과 화면 (순차적 애니메이션 렌더링)
class StaggeredResultContentView extends StatefulWidget {
  final CoachingResponse coaching;
  final Set<String> selectedUuids;
  final bool isFetching;
  final VoidCallback onSelectHistory;
  final VoidCallback onRequestCoaching;

  const StaggeredResultContentView({
    super.key,
    required this.coaching,
    required this.selectedUuids,
    required this.isFetching,
    required this.onSelectHistory,
    required this.onRequestCoaching,
  });

  @override
  State<StaggeredResultContentView> createState() => _StaggeredResultContentViewState();
}

class _StaggeredResultContentViewState extends State<StaggeredResultContentView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// AI 메시지 문자열 분리/정제 헬퍼 함수
  ({String summary, List<String> detailList}) _parseCoachingMessage(String rawMessage) {
    final String trimmed = rawMessage.trim();
    if (trimmed.isEmpty) return (summary: '', detailList: []);

    final List<String> lines = trimmed.split('\n');
    final String summary = lines.first.replaceAll('**', '').trim();

    List<String> detailList = [];
    if (lines.length > 1) {
      detailList = lines
          .sublist(1)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^\s*[\-\•\*\d\.]+\s*'), '').trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }

    return (summary: summary, detailList: detailList);
  }

  @override
  Widget build(BuildContext context) {
    final coaching = widget.coaching;
    final isSingle = coaching.coachingType == 'SINGLE';
    final parsed = _parseCoachingMessage(coaching.coachingMessage);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
      children: [
        AiCoachingSloganBanner(
          slogan: parsed.summary.isNotEmpty ? parsed.summary : null,
          animationController: _controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메인 요약 및 데이터 카드
              DirectionalSlideFade(
                controller: _controller,
                beginInterval: 0.36,
                endInterval: 0.58,
                direction: SlideDirection.bottomToTop,
                offsetDistance: 45.0,
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-0.4, -0.9),
                      end: Alignment(0.4, 0.9),
                      colors: [
                        Color(0xFFF5F0FF),
                        Color(0xFFEDE9FE),
                        Color(0xFFFAFAFF),
                        Color(0xFFEFF6FF),
                      ],
                      stops: [0.0, 0.28, 0.60, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                      const BoxShadow(
                        color: Color.fromRGBO(23, 32, 64, 0.04),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSingle
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.1)
                                    : const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 13,
                                    color: isSingle ? const Color(0xFF0284C7) : const Color(0xFF7C3AED),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isSingle ? '단일 세트 분석' : '통합 분석',
                                    style: GoogleFonts.dmSans(
                                      color: isSingle ? const Color(0xFF0284C7) : const Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${coaching.totalSessions}세트 분석됨',
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.45,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: [
                            _MetricTile(
                              label: '정상 스쿼트',
                              count: coaching.totalSuccessCount,
                              color: const Color(0xFF10B981),
                              icon: Icons.check_circle_outline_rounded,
                            ),
                            _MetricTile(
                              label: '허리 과숙임',
                              count: coaching.totalWaistErrorCount,
                              color: const Color(0xFFF59E0B),
                              icon: Icons.error_outline_rounded,
                            ),
                            _MetricTile(
                              label: '얕은 깊이',
                              count: coaching.totalDepthErrorCount,
                              color: const Color(0xFFF97316),
                              icon: Icons.arrow_downward_rounded,
                            ),
                            _MetricTile(
                              label: '상체 선행',
                              count: coaching.totalGoodMorningCount,
                              color: const Color(0xFFEF4444),
                              icon: Icons.trending_up_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 세부 분석 메시지 리스트 순차 등장
              if (parsed.detailList.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...List.generate(parsed.detailList.length, (index) {
                  final double start = (0.42 + (index * 0.04)).clamp(0.0, 0.75);
                  final double end = (start + 0.15).clamp(start + 0.05, 0.88);

                  return DirectionalSlideFade(
                    controller: _controller,
                    beginInterval: start,
                    endInterval: end,
                    direction: SlideDirection.topToBottom,
                    curve: Curves.easeOutCubic,
                    offsetDistance: 24.0,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySky,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primarySky.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildRichText(
                              parsed.detailList[index],
                              baseStyle: TextStyle(
                                fontFamily: 'Pretendard',
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14.5,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 하단 액션 버튼 슬라이드 애니메이션
        DirectionalSlideFade(
          controller: _controller,
          beginInterval: 0.80,
          endInterval: 0.95,
          direction: SlideDirection.bottomToTop,
          offsetDistance: 20.0,
          child: _ActionButtons(
            isFetching: widget.isFetching,
            selectedUuids: widget.selectedUuids,
            onSelectHistory: widget.onSelectHistory,
            onRequestCoaching: widget.onRequestCoaching,
          ),
        ),
      ],
    );
  }

  /// 마크다운 강세(`**`)를 파싱하여 Bold 텍스트 지원하는 RichText 생성
  static Widget _buildRichText(String text, {required TextStyle baseStyle}) {
    final List<TextSpan> spans = [];
    final List<String> parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;

      if (i % 2 == 1) {
        spans.add(
          TextSpan(
            text: parts[i],
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: parts[i],
            style: baseStyle,
          ),
        );
      }
    }

    return Text.rich(TextSpan(children: spans));
  }
}

/// 측정지표 단일 카드 타일
class _MetricTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.095),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$count",
                style: GoogleFonts.anton(
                  fontSize: 28,
                  color: color,
                  height: 1.0,
                  letterSpacing: 0.56,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                "회",
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DirectionalSlideFade
// =============================================================================

enum SlideDirection { topToBottom, bottomToTop }

/// 구간 설정 가능한 상/하 슬라이드 & 페이드 인 위젯
class DirectionalSlideFade extends StatelessWidget {
  final AnimationController controller;
  final double beginInterval;
  final double endInterval;
  final SlideDirection direction;
  final double offsetDistance;
  final Curve curve;
  final Widget child;

  const DirectionalSlideFade({
    super.key,
    required this.controller,
    required this.beginInterval,
    required this.endInterval,
    this.direction = SlideDirection.bottomToTop,
    this.offsetDistance = 40.0,
    this.curve = Curves.easeOutBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        beginInterval.clamp(0.0, 1.0),
        endInterval.clamp(0.0, 1.0),
        curve: curve,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double sign = (direction == SlideDirection.bottomToTop) ? 1.0 : -1.0;
        final double currentOffset = (1.0 - animation.value) * offsetDistance * sign;

        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, currentOffset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// =============================================================================
// AiCoachingSloganBanner
// =============================================================================

/// 상단 슬로건 배너 (기본 슬로건 순환 및 애니메이션 제공)
class AiCoachingSloganBanner extends StatefulWidget {
  final String? slogan;
  final Widget child;
  final AnimationController? animationController;

  const AiCoachingSloganBanner({
    super.key,
    this.slogan,
    required this.child,
    this.animationController,
  });

  @override
  State<AiCoachingSloganBanner> createState() => _AiCoachingSloganBannerState();
}

class _AiCoachingSloganBannerState extends State<AiCoachingSloganBanner> {
  static const Curve appCubicCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  static const List<String> _defaultQuotes = [
    "AI가 분석하는 나만의 맞춤 스쿼트 피드백",
    "AI 코치와 함께 완성하는 바른 스쿼트 자세",
    "운동 기록을 기반으로 시작하는 AI 코칭",
    "데이터로 정밀하게 분석하는 나의 스쿼트",
    "AI 피드백으로 더 스마트해지는 운동 루틴",
  ];

  Timer? _timer;
  int _currentIndex = 0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _checkAndStartTimer();
  }

  @override
  void didUpdateWidget(covariant AiCoachingSloganBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slogan != oldWidget.slogan) {
      _checkAndStartTimer();
    }
  }

  void _checkAndStartTimer() {
    _timer?.cancel();
    if (widget.slogan == null || widget.slogan!.isEmpty) {
      _startBannerTimer();
    } else {
      setState(() {
        _isVisible = true;
      });
    }
  }

  void _startBannerTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 6000), (timer) async {
      if (!mounted) return;
      setState(() => _isVisible = false);

      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted || (widget.slogan != null && widget.slogan!.isNotEmpty)) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % _defaultQuotes.length;
        _isVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSlogan = widget.slogan != null && widget.slogan!.isNotEmpty;
    final String currentText = hasSlogan ? widget.slogan! : _defaultQuotes[_currentIndex];

    Widget sloganTextWidget = Container(
      key: ValueKey<String>(currentText),
      alignment: Alignment.centerLeft,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primarySky.withValues(alpha: 0.75),
              AppTheme.primarySky.withValues(alpha: 0.0),
            ],
          ).createShader(bounds);
        },
        child: Text(
          currentText,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    if (widget.animationController != null) {
      final sloganAnimation = CurvedAnimation(
        parent: widget.animationController!,
        curve: const Interval(
          0.05,
          0.28,
          curve: appCubicCurve,
        ),
      );

      sloganTextWidget = AnimatedBuilder(
        animation: sloganAnimation,
        builder: (context, child) {
          final double translateY = -10.0 * (1.0 - sloganAnimation.value);
          return Transform.translate(
            offset: Offset(0.0, translateY),
            child: Opacity(
              opacity: sloganAnimation.value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: sloganTextWidget,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1300),
            reverseDuration: const Duration(milliseconds: 700),
            switchInCurve: appCubicCurve,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final double translateY = -10.0 * (1.0 - animation.value);
                  return Transform.translate(
                    offset: Offset(0.0, translateY),
                    child: Opacity(
                      opacity: animation.value,
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            child: _isVisible
                ? sloganTextWidget
                : const SizedBox.shrink(key: ValueKey<String>('empty_space')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 80.0),
          child: widget.child,
        ),
      ],
    );
  }
}

// =============================================================================
// AiAnalysisFullScreenLoading
// =============================================================================

/// AI 분석 진행 중 풀스크린 로딩 뷰
class AiAnalysisFullScreenLoading extends StatefulWidget {
  final VoidCallback? onComplete;

  const AiAnalysisFullScreenLoading({super.key, this.onComplete});

  @override
  State<AiAnalysisFullScreenLoading> createState() => _AiAnalysisFullScreenLoadingState();
}

class _AiAnalysisFullScreenLoadingState extends State<AiAnalysisFullScreenLoading>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _currentStep = 0;

  static const List<String> _stepMessages = [
    "스쿼트 데이터를 수집하고 있습니다.",
    "Gemini AI 스쿼트 분석을 시작합니다.",
    "맞춤 피드백 리포트를 생성 중입니다.",
    "모든 분석이 완료되었습니다!",
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _startStepProgress();
  }

  void _startStepProgress() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _currentStep = 1);

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _currentStep = 2);

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _currentStep = 3);

    // AI 분석이 끝날 때까지 대기
    if (mounted) {
      final provider = context.read<CoachingProvider>();
      while (provider.isAiAnalyzing && mounted) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    if (widget.onComplete != null && mounted) {
      widget.onComplete!();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> steps = [
      {
        'label': '데이터 수집',
        'icon': Icons.check_circle_outline_rounded,
        'bg': const Color(0xFFEFF6FF),
        'border': const Color(0xFF0284C7).withValues(alpha: 0.20),
        'activeBorder': const Color(0xFF0284C7),
        'iconColor': const Color(0xFF0284C7),
      },
      {
        'label': 'AI 분석',
        'icon': Icons.auto_awesome_rounded,
        'bg': const Color(0xFFF3E8FF),
        'border': const Color(0xFF7C3AED).withValues(alpha: 0.20),
        'activeBorder': const Color(0xFF7C3AED),
        'iconColor': const Color(0xFF7C3AED),
      },
      {
        'label': '리포트 생성',
        'icon': Icons.description_rounded,
        'bg': const Color(0xFFECFDF5),
        'border': const Color(0xFF10B981).withValues(alpha: 0.20),
        'activeBorder': const Color(0xFF10B981),
        'iconColor': const Color(0xFF10B981),
      },
    ];

    return ColoredBox(
      color: AppTheme.lightBackground,
      child: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // A. Hero Orbit Visual
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _rotationController,
                          child: CustomPaint(
                            size: const Size(140, 140),
                            painter: _DashedCirclePainter(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                              strokeWidth: 2.0,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final double t = _pulseAnimation.value;
                            return Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF7C3AED).withValues(alpha: 0.08 + (0.16 * t)),
                                    const Color(0xFF7C3AED).withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.75],
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final double t = _pulseAnimation.value;
                            return Transform.scale(
                              scale: 0.95 + (0.08 * t),
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment(-0.5, -0.8),
                                    end: Alignment(0.5, 0.8),
                                    colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF9D4EDD),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.10 + (0.10 * t)),
                                      spreadRadius: 6 + (6 * t),
                                      blurRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.25 + (0.20 * t)),
                                      blurRadius: 20 + (12 * t),
                                      offset: Offset(0, 6 + (6 * t)),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 34,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x383B82F6),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3810B981),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // B. Title & Subtitle
                  Text(
                    "AI 스쿼트 자세 분석 중",
                    style: GoogleFonts.anton(
                      fontSize: 24,
                      letterSpacing: 0.6,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "POWERED BY GEMINI AI",
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C3AED),
                      letterSpacing: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // C. 3-Step Flow Strip
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(steps.length * 2 - 1, (index) {
                      if (index.isEven) {
                        final stepIndex = index ~/ 2;
                        final step = steps[stepIndex];

                        final isDone = stepIndex < _currentStep;
                        final isCurrent = stepIndex == _currentStep;
                        final isUpcoming = stepIndex > _currentStep;

                        final Color currentBorderColor = isCurrent
                            ? (step['activeBorder'] as Color)
                            : (step['border'] as Color);

                        final double opacity = isUpcoming ? 0.45 : 1.0;

                        return Expanded(
                          child: Opacity(
                            opacity: opacity,
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: step['bg'] as Color,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: currentBorderColor,
                                      width: isCurrent ? 2.0 : 1.2,
                                    ),
                                    boxShadow: isCurrent
                                        ? [
                                      BoxShadow(
                                        color: (step['iconColor'] as Color).withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                        : [],
                                  ),
                                  child: Icon(
                                    isDone ? Icons.check_rounded : (step['icon'] as IconData),
                                    size: 22,
                                    color: step['iconColor'] as Color,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step['label'] as String,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: isCurrent || isDone ? FontWeight.w800 : FontWeight.w700,
                                    color: isCurrent
                                        ? (step['iconColor'] as Color)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final stepIndex = index ~/ 2;
                      final isPassed = stepIndex < _currentStep;
                      final Color arrowColor = isPassed
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.20);

                      return Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 18,
                              height: 2,
                              color: arrowColor,
                            ),
                            CustomPaint(
                              size: const Size(5, 8),
                              painter: _ArrowHeadPainter(color: arrowColor),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // D. Dynamic Live Status Indicator
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey<int>(_currentStep),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _currentStep == 3
                              ? const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          )
                              : const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _stepMessages[_currentStep],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _currentStep == 3
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF7C3AED),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AIHeroPlaceholder
// =============================================================================

/// 결과 데이터가 없을 때 표시되는 초기 히어로 그래픽 카드
class AIHeroPlaceholder extends StatefulWidget {
  final int selectedCount;

  const AIHeroPlaceholder({
    super.key,
    required this.selectedCount,
  });

  @override
  State<AIHeroPlaceholder> createState() => _AIHeroPlaceholderState();
}

class _AIHeroPlaceholderState extends State<AIHeroPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.selectedCount > 0;

    final List<Map<String, dynamic>> steps = [
      {
        'label': '기록 선택',
        'icon': Icons.check_circle_outline_rounded,
        'bg': const Color(0xFFEFF6FF),
        'border': const Color(0xFF0284C7).withValues(alpha: 0.20),
        'iconColor': const Color(0xFF0284C7),
      },
      {
        'label': 'AI 분석',
        'icon': Icons.auto_awesome_rounded,
        'bg': const Color(0xFFF3E8FF),
        'border': const Color(0xFF7C3AED).withValues(alpha: 0.20),
        'iconColor': const Color(0xFF7C3AED),
      },
      {
        'label': '결과 확인',
        'icon': Icons.description_rounded,
        'bg': const Color(0xFFECFDF5),
        'border': const Color(0xFF10B981).withValues(alpha: 0.20),
        'iconColor': const Color(0xFF10B981),
      },
    ];

    return AspectRatio(
      aspectRatio: 1.19,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.4, -0.9),
            end: Alignment(0.4, 0.9),
            colors: [
              Color(0xFFF5F0FF),
              Color(0xFFEDE9FE),
              Color(0xFFFAFAFF),
              Color(0xFFEFF6FF),
            ],
            stops: [0.0, 0.28, 0.60, 1.0],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            const BoxShadow(
              color: Color.fromRGBO(23, 32, 64, 0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -24,
              right: -20,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Color(0x170EA5E9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -16,
              left: -10,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0x127C3AED),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 82,
                    width: 82,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(82, 82),
                          painter: _DashedCirclePainter(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
                            strokeWidth: 1.5,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            final double t = _glowAnimation.value;
                            return Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF7C3AED).withValues(alpha: 0.05 + (0.12 * t)),
                                    const Color(0xFF7C3AED).withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.72],
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            final double t = _glowAnimation.value;
                            return Transform.scale(
                              scale: 0.95 + (0.08 * t),
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment(-0.5, -0.8),
                                    end: Alignment(0.5, 0.8),
                                    colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF9D4EDD),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.05 + (0.05 * t)),
                                      spreadRadius: 4 + (4 * t),
                                      blurRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.18 + (0.16 * t)),
                                      blurRadius: 14 + (10 * t),
                                      offset: Offset(0, 4 + (4 * t)),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x383B82F6),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 10,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3810B981),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              size: 10,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "AI 스쿼트 분석",
                        style: GoogleFonts.anton(
                          fontSize: 19,
                          letterSpacing: 0.6,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "POWERED BY GEMINI AI",
                        style: GoogleFonts.dmSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C3AED),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(steps.length * 2 - 1, (index) {
                      if (index.isEven) {
                        final stepIndex = index ~/ 2;
                        final step = steps[stepIndex];
                        return Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: step['bg'] as Color,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: step['border'] as Color, width: 1.2),
                                ),
                                child: Icon(
                                  step['icon'] as IconData,
                                  size: 14,
                                  color: step['iconColor'] as Color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                step['label'] as String,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 1.5,
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
                            ),
                            CustomPaint(
                              size: const Size(4, 7),
                              painter: _ArrowHeadPainter(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0284C7).withValues(alpha: 0.20)
                            : const Color(0xFF7C3AED).withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF7C3AED),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.25)
                                    : const Color(0xFF7C3AED).withValues(alpha: 0.25),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isSelected
                                ? "${widget.selectedCount}개 선택됨 · 분석 버튼을 눌러주세요"
                                : "아래 기록을 선택해 분석을 시작하세요",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF7C3AED),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Custom Painters
// =============================================================================

/// 점선 원 캔버스 렌더러
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const int totalSegments = 90;
    const double stepArc = (2 * math.pi) / totalSegments; // math.pi 활용

    for (int i = 0; i < totalSegments; i += 2) {
      canvas.drawArc(
        rect,
        i * stepArc,
        stepArc * 0.85,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 단방향 화살표 머리 렌더러
class _ArrowHeadPainter extends CustomPainter {
  final Color color;

  _ArrowHeadPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowHeadPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}