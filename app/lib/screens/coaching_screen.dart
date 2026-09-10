import 'dart:async';
import 'package:app/screens/select_coaching_record_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/coaching_provider.dart';
import '../dtos/aggregate_coaching_request.dart';
import '../theme/app_theme.dart';

class CoachingScreen extends StatefulWidget {
  const CoachingScreen({super.key});

  @override
  State<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends State<CoachingScreen> {
  // 선택된 서버 기록 UUID(String) 목록
  final Set<String> _selectedServerUuids = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachingProvider>().fetchServerRecords();
    });
  }

  void _onRefresh() {
    // 1. 선택된 UUID 목록 비우기
    setState(() => _selectedServerUuids.clear());

    final provider = context.read<CoachingProvider>();

    // 2. AI 분석 결과 및 에러 상태 초기화 (처음 화면으로 돌아감)
    provider.resetCoaching();
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
            final isLoading = provider.isLoading;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              children: [
                // 1. 헤더 (상단 타이틀 & 초기화 버튼)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(),
                    // 초기화 버튼
                    InkWell(
                      onTap: _onRefresh,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text(
                              "초기화",
                              style: TextStyle(
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
                const SizedBox(height: 16),

                // 2. AI 분석 결과 / 로딩 / 에러 / 안내 카드 영역
                if (isLoading)
                  _buildLoadingCard()
                else if (coaching != null)
                  _buildResultCard(coaching)
                else if (errorMessage != null)
                    _buildErrorCard(errorMessage)
                  else
                    _buildPlaceholderCard(_selectedServerUuids.length),

                const SizedBox(height: 16),

                // 3. 하단 액션 버튼 영역 (Row 가로 배치)
                Row(
                  children: [
                    // [왼쪽] 기록 보기 및 선택 버튼
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () async {
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

                    // [오른쪽] AI 분석 요청 버튼
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final isEnabled = _selectedServerUuids.isNotEmpty && !isLoading;

                          return AnimatedContainer(
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
                                  onTap: isEnabled
                                      ? () async {
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
                                      : null,
                                  borderRadius: BorderRadius.circular(isEnabled ? 16.2 : 18),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: isEnabled
                                              ? const Color(0xFF0284C7)
                                              : const Color(0xFF94A3B8),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _selectedServerUuids.isNotEmpty
                                                ? "AI 분석 요청 (${_selectedServerUuids.length})"
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// AI 코칭 탭 상단 헤더
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

  // ── AI 결과 분석용 상태별 서브 카드 빌더 ──
  Widget _buildPlaceholderCard(int selectedCount) {
    return AiCoachingSloganBanner(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 32),
            const SizedBox(height: 8),
            const Text(
              "AI 분석 결과",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              selectedCount > 0
                  ? "$selectedCount개 선택됨 · [AI 분석 요청]을 누르세요"
                  : "하단 [기록 보기 및 선택]에서 기록 선택 후 AI 분석을 시작하세요",
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 기존 _buildLoadingCard() 메서드를 아래 위젯 반환으로 교체
  Widget _buildLoadingCard() {
    return const AiCoachingSloganBanner(
      child: AiAnalysisLoadingCard(),
    );
  }

  /// AI 코칭 결과 카드
  Widget _buildResultCard(dynamic coaching) {
    final isSingle = coaching.coachingType == 'SINGLE';

    final String rawMessage = (coaching.coachingMessage ?? '').trim();
    String summary = '';
    List<String> detailList = [];

    // 1. 파싱 로직 (슬로건 분리 및 불릿 단위 분할)
    if (rawMessage.isNotEmpty) {
      final List<String> lines = rawMessage.split('\n');
      summary = lines.first.replaceAll('**', '').trim();

      if (lines.length > 1) {
        detailList = lines
            .sublist(1)
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .map((line) {
          return line.replaceAll(RegExp(r'^\s*[\-\•\*\d\.]+\s*'), '').trim();
        })
            .where((line) => line.isNotEmpty)
            .toList();
      }
    }

    return AiCoachingSloganBanner(
      slogan: summary.isNotEmpty ? summary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. [상단] 메트릭 카드
          Container(
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

          // 2. [하단] 개별 분리된 AI 코멘트 카드
          if (detailList.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...detailList.map((detailText) {
              return Container(
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
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRichText(
                        detailText,
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
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRichText(String text, {required TextStyle baseStyle}) {
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

    return Text.rich(
      TextSpan(children: spans),
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

  Widget _buildMetricTile(String label, int count, Color color, IconData icon) {
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
                child: Icon(
                  icon,
                  size: 15,
                  color: color,
                ),
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
// 홈 화면 MotivationalBanner와 동일한 Stack 구조 기반 슬로건 래퍼 위젯
// =============================================================================
class AiCoachingSloganBanner extends StatefulWidget {
  final String? slogan;
  final Widget child; // 하단에 배치될 카드/위젯

  const AiCoachingSloganBanner({
    super.key,
    this.slogan,
    required this.child,
  });

  @override
  State<AiCoachingSloganBanner> createState() => _AiCoachingSloganBannerState();
}

class _AiCoachingSloganBannerState extends State<AiCoachingSloganBanner> {
  // 홈 화면과 동일한 Cubic-Bezier 곡선 지정
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
    // 8.5초마다 주기적으로 교체 (1초간 빈 공간 텀 유지)
    _timer = Timer.periodic(const Duration(milliseconds: 6000), (timer) async {
      if (!mounted) return;

      // 1. 기존 문구 페이드 아웃
      setState(() => _isVisible = false);

      // 2. 홈 화면과 동일하게 1초간 여운(텀) 유지
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted || (widget.slogan != null && widget.slogan!.isNotEmpty)) return;

      // 3. 다음 문구 설정 후 페이드 인
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. 상단 배경 레이어에 독립 배치되는 슬로건 애니메이션
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
                ? Container(
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
            )
                : const SizedBox.shrink(key: ValueKey<String>('empty_space')),
          ),
        ),

        // 2. 슬로건 높이만큼 오프셋(top: 80.0)을 주고 하단 카드 배치
        Padding(
          padding: const EdgeInsets.only(top: 80.0),
          child: widget.child,
        ),
      ],
    );
  }
}

// =============================================================================
// 고급스러운 AI 분석 진행 로딩 카드 위젯
// =============================================================================
class AiAnalysisLoadingCard extends StatefulWidget {
  const AiAnalysisLoadingCard({super.key});

  @override
  State<AiAnalysisLoadingCard> createState() => _AiAnalysisLoadingCardState();
}

class _AiAnalysisLoadingCardState extends State<AiAnalysisLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  Timer? _stepTimer;
  int _currentStep = 0;

  // 대기 시간 동안 순차적으로 변경될 AI 분석 단계 메시지
  static const List<Map<String, String>> _steps = [
    {
      "title": "운동 데이터 수집 중...",
      "subtitle": "센서에 기록된 스쿼트 궤적을 확인하고 있습니다",
    },
    {
      "title": "AI 자세 밸런스 분석 중...",
      "subtitle": "상체 기울기와 무릎 깊이의 정확도를 계산합니다",
    },
    {
      "title": "맞춤 코칭 리포트 작성 중...",
      "subtitle": "운동 효과를 높여줄 맞춤 피드백을 구성하고 있습니다",
    },
  ];

  @override
  void initState() {
    super.initState();

    // 1. AI 아이콘 호흡(Pulse) 애니메이션 설정
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. 대기 시간 동안 단계별 메시지 자동 전환 (약 1.8초 마다 단계 상승)
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
      child: Column(
        children: [
          // 1. 중앙 호흡하는 AI 펄스 아이콘 영역
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 외곽 은은한 후광 링
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value * 1.25,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF38BDF8).withValues(alpha: _opacityAnimation.value * 0.25),
                        ),
                      ),
                    );
                  },
                ),
                // 내부 아이콘 메인 원
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. 단계별 타이틀 애니메이션 스위처
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Column(
              key: ValueKey<int>(_currentStep),
              children: [
                Text(
                  currentStepData["title"]!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentStepData["subtitle"]!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 3. 하단 3단계 프로그레스 닷(Dot) 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (index) {
              final isCompleted = index <= _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: index == _currentStep ? 24 : 6,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}