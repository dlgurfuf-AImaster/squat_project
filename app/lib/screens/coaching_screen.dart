import 'dart:async';
import 'package:app/screens/select_coaching_record_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/coaching_provider.dart';
import '../dtos/aggregate_coaching_request.dart';
import '../dtos/coaching_response.dart';
import '../theme/app_theme.dart';

class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen> {
  final Set<String> _selectedServerUuids = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachingProvider>().fetchServerRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                // 1. [상단 헤더]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeader(),
                      InkWell(
                        onTap: (isFetching || isAiAnalyzing)
                            ? null
                            : () {
                          provider.resetCoaching();
                          setState(() {
                            _selectedServerUuids.clear();
                          });
                        },
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
                      ),
                    ],
                  ),
                ),

                // 2. [메인 콘텐츠 영역]
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
                      onSelectHistory: () async {
                        final selected = await Navigator.push<Set<String>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectCoachingRecordScreen(),
                          ),
                        );
                        if (selected != null) {
                          setState(() {
                            _selectedServerUuids.clear();
                            _selectedServerUuids.addAll(selected);
                          });
                        }
                      },
                      onRequestCoaching: () async {
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
                      },
                    )
                        : ListView(
                      key: const ValueKey('normal_screen'),
                      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
                      children: [
                        if (errorMessage != null)
                          _buildErrorCard(errorMessage)
                        else
                          _buildPlaceholderCard(_selectedServerUuids.length),

                        const SizedBox(height: 16),

                        _buildActionButtons(
                          isFetching: isFetching,
                          selectedUuids: _selectedServerUuids,
                          onSelectHistory: () async {
                            final selected = await Navigator.push<Set<String>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SelectCoachingRecordScreen(),
                              ),
                            );
                            if (selected != null) {
                              setState(() {
                                _selectedServerUuids.clear();
                                _selectedServerUuids.addAll(selected);
                              });
                            }
                          },
                          onRequestCoaching: () async {
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
                          },
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
    );
  }

  Widget _buildHeader() {
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

  // ===========================================================================
  // AI 스쿼트 분석 파트
  // ===========================================================================
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
                style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildActionButtons({
    required bool isFetching,
    required Set<String> selectedUuids,
    required VoidCallback onSelectHistory,
    required VoidCallback onRequestCoaching,
  }) {
    final isEnabled = selectedUuids.isNotEmpty && !isFetching;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: onSelectHistory,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFE0F2FE),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 18, color: Color(0xFF0284C7)),
                  SizedBox(width: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "기록 보기 및 선택",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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
                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
                  : [],
            ),
            padding: EdgeInsets.all(isEnabled ? 1.8 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.white : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(isEnabled ? 16.2 : 18),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? onRequestCoaching : null,
                  borderRadius: BorderRadius.circular(isEnabled ? 16.2 : 18),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: isEnabled ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            selectedUuids.isNotEmpty
                                ? "AI 분석 요청 (${selectedUuids.length})"
                                : "AI 분석 요청",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
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
        ),
      ],
    );
  }
}

// =============================================================================
// StaggeredResultContentView
// =============================================================================
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

  @override
  Widget build(BuildContext context) {
    final coaching = widget.coaching;
    final isSingle = coaching.coachingType == 'SINGLE';
    final String rawMessage = (coaching.coachingMessage ?? '').trim();

    String summary = '';
    List<String> detailList = [];

    if (rawMessage.isNotEmpty) {
      final List<String> lines = rawMessage.split('\n');
      summary = lines.first.replaceAll('**', '').trim();

      if (lines.length > 1) {
        detailList = lines
            .sublist(1)
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^\s*[\-\•\*\d\.]+\s*'), '').trim())
            .where((line) => line.isNotEmpty)
            .toList();
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
      children: [
        AiCoachingSloganBanner(
          slogan: summary.isNotEmpty ? summary : null,
          animationController: _controller,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DirectionalSlideFade(
                controller: _controller,
                beginInterval: 0.36,
                endInterval: 0.58,
                direction: SlideDirection.bottomToTop,
                offsetDistance: 45.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
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
                            _buildMetricTile('정상 스쿼트', coaching.totalSuccessCount, const Color(0xFF10B981), Icons.check_circle_outline_rounded),
                            _buildMetricTile('허리 과숙임', coaching.totalWaistErrorCount, const Color(0xFFF59E0B), Icons.error_outline_rounded),
                            _buildMetricTile('얕은 깊이', coaching.totalDepthErrorCount, const Color(0xFF8B5CF6), Icons.arrow_downward_rounded),
                            _buildMetricTile('상체 선행', coaching.totalGoodMorningCount, const Color(0xFFEF4444), Icons.trending_up_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (detailList.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...List.generate(detailList.length, (index) {
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
                              detailList[index],
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

        const SizedBox(height: 16),

        DirectionalSlideFade(
          controller: _controller,
          beginInterval: 0.80,
          endInterval: 0.95,
          direction: SlideDirection.bottomToTop,
          offsetDistance: 20.0,
          child: _CoachingScreenState._buildActionButtons(
            isFetching: widget.isFetching,
            selectedUuids: widget.selectedUuids,
            onSelectHistory: widget.onSelectHistory,
            onRequestCoaching: widget.onRequestCoaching,
          ),
        ),
      ],
    );
  }

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

  static Widget _buildMetricTile(String label, int count, Color color, IconData icon) {
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
          0.05, 0.28,
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
class AiAnalysisFullScreenLoading extends StatefulWidget {
  const AiAnalysisFullScreenLoading({super.key});

  @override
  State<AiAnalysisFullScreenLoading> createState() => _AiAnalysisFullScreenLoadingState();
}

class _AiAnalysisFullScreenLoadingState extends State<AiAnalysisFullScreenLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  Timer? _stepTimer;
  int _currentStep = 0;

  static const List<Map<String, String>> _steps = [
    {
      "title": "운동 데이터 수집 중",
      "subtitle": "센서에 측정된 스쿼트 궤적과 관절 각도를 수집합니다",
    },
    {
      "title": "AI 자세 밸런스 정밀 측정",
      "subtitle": "상체 숙임과 무릎 깊이의 안정성을 분석하고 있습니다",
    },
    {
      "title": "맞춤 코칭 리포트 생성 중",
      "subtitle": "운동 성과와 부상 예방을 위한 피드백을 작성합니다",
    },
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (!mounted) return;
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _steps[_currentStep];

    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: const BoxDecoration(
          color: AppTheme.lightBackground,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value * 1.45,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF38BDF8).withValues(alpha: _opacityAnimation.value * 0.15),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value * 1.2,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0284C7).withValues(alpha: _opacityAnimation.value * 0.3),
                          ),
                        ),
                      );
                    },
                  ),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Column(
                key: ValueKey<int>(_currentStep),
                children: [
                  Text(
                    currentStepData["title"]!,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentStepData["subtitle"]!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                final isCompleted = index <= _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 7,
                  width: index == _currentStep ? 32 : 8,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// AIHeroPlaceholder
// =============================================================================
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
      duration: const Duration(milliseconds: 1800),
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
        'icon': Icons.ads_click_rounded,
        'bg': const Color(0xFF7C3AED).withValues(alpha: 0.08),
        'border': const Color(0xFF7C3AED).withValues(alpha: 0.20),
        'iconColor': const Color(0xFF7C3AED),
      },
      {
        'label': 'AI 분석',
        'icon': Icons.auto_awesome_rounded,
        'bg': const Color(0xFF0284C7).withValues(alpha: 0.08),
        'border': const Color(0xFF0284C7).withValues(alpha: 0.20),
        'iconColor': const Color(0xFF0284C7),
      },
      {
        'label': '결과 확인',
        'icon': Icons.assessment_rounded,
        'bg': const Color(0xFF10B981).withValues(alpha: 0.08),
        'border': const Color(0xFF10B981).withValues(alpha: 0.20),
        'iconColor': const Color(0xFF10B981),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Hero Visual (글로우 애니메이션 + 점선 원)
          SizedBox(
            height: 110,
            width: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(110, 110),
                  painter: _DashedCirclePainter(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                  ),
                ),
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _glowAnimation.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.35 * _glowAnimation.value),
                              blurRadius: 16 * _glowAnimation.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 30,
                  color: Colors.white,
                ),
                Positioned(
                  top: 2,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      size: 14,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Title & Subtitle
          Text(
            "AI 스쿼트 분석",
            style: GoogleFonts.anton(
              fontSize: 20,
              letterSpacing: 0.6,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "POWERED BY GEMINI AI",
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7C3AED),
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 20),

          // 3. 3-Step Flow Strip
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: step['bg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: step['border'] as Color, width: 1.2),
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          size: 16,
                          color: step['iconColor'] as Color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step['label'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
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
                      width: 14,
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

          const SizedBox(height: 20),

          // 4. Live Selected Status Indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0284C7).withValues(alpha: 0.20)
                    : const Color(0xFFE2E8F0),
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
                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isSelected
                        ? "${widget.selectedCount}개 선택됨 · 준비 완료"
                        : "기록을 선택해 분석을 시작해보세요",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Custom Painters
// =============================================================================
class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    const dashCount = 20;
    const dashArc = (2 * 3.141592653589793) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          i * dashArc,
          dashArc * 0.6,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

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