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
    setState(() => _selectedServerUuids.clear());
    Provider.of<CoachingProvider>(context, listen: false).fetchServerRecords();
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

                // 3. 하단 액션 버튼 영역 (Column 배치)
                Column(
                  children: [
                    // AI 분석 요청 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_selectedServerUuids.isEmpty || isLoading)
                            ? null
                            : () async {
                          if (_selectedServerUuids.length == 1) {
                            await provider.requestSingleCoaching(_selectedServerUuids.first);
                          } else {
                            await provider.requestAggregateCoaching(
                              AggregateCoachingRequest.byUuids(_selectedServerUuids.toList()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: _selectedServerUuids.isNotEmpty ? 4 : 0,
                          shadowColor: AppTheme.primarySky.withValues(alpha: 0.4),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _selectedServerUuids.isNotEmpty && !isLoading
                                ? const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)])
                                : null,
                            color: _selectedServerUuids.isNotEmpty && !isLoading
                                ? null
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: _selectedServerUuids.isNotEmpty && !isLoading
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedServerUuids.isNotEmpty
                                      ? "선택한 (${_selectedServerUuids.length})개 데이터 AI 분석 요청"
                                      : "기록을 선택해 주세요",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedServerUuids.isNotEmpty && !isLoading
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 기록 보기 버튼 (AI 분석 요청 버튼 하단 배치)
                    SizedBox(
                      width: double.infinity,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 20, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Text(
                              "기록 보기 및 선택",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
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
    return Container(
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
          const Text("AI 분석 결과", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(
            selectedCount > 0 ? "$selectedCount개 선택됨 · 아래 버튼으로 분석을 요청하세요" : "하단 [기록 보기 및 선택]에서 기록 선택 후 AI 분석을 시작하세요",
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF0284C7)),
          SizedBox(height: 16),
          Text("AI 분석 진행 중...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
          SizedBox(height: 6),
          Text("Gemini AI가 스쿼트 자세를 분석하고 있습니다...", style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ],
      ),
    );
  }

  /// AI 코칭 결과 카드
  Widget _buildResultCard(dynamic coaching) {
    final isSingle = coaching.coachingType == 'SINGLE';

    // 💡 1. JSON 파싱 대신 줄바꿈(\n) 기준으로 첫 줄과 나머지 분리
    final String rawMessage = (coaching.coachingMessage ?? '').trim();

    String summary = '';
    String details = '';

    if (rawMessage.isNotEmpty) {
      final List<String> lines = rawMessage.split('\n');

      // 첫 번째 줄: 핵심 요약 (마크다운 ** 제거하여 깔끔하게 표시)
      summary = lines.first.replaceAll('**', '').trim();

      // 두 번째 줄 이후: 불릿 포인트 상세 내용
      if (lines.length > 1) {
        details = lines.sublist(1).join('\n').replaceAll('**', '').trim();
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSingle ? '단일 세트 분석 결과' : '종합/누적 분석 결과',
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${coaching.totalSessions}개 세트 분석됨',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildMetricTile('정상', coaching.totalSuccessCount, const Color(0xFF10B981)),
              _buildMetricTile('허리과숙임', coaching.totalWaistErrorCount, const Color(0xFFF59E0B)),
              _buildMetricTile('얕은깊이', coaching.totalDepthErrorCount, const Color(0xFFF97316)),
              _buildMetricTile('상체선행', coaching.totalGoodMorningCount, const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 12),

          // 💡 2. 첫 줄 요약 및 상세 불릿 포인트 피드백 출력
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.smart_toy, color: Color(0xFF7C3AED), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 첫 줄 요약 (굵은 글씨)
                      if (summary.isNotEmpty) ...[
                        Text(
                          summary,
                          style: const TextStyle(
                            color: Color(0xFF5B21B6),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (details.isNotEmpty) const SizedBox(height: 8),
                      ],
                      // 상세 불릿 포인트 피드백
                      if (details.isNotEmpty)
                        Text(
                          details,
                          style: const TextStyle(
                            color: Color(0xFF4C1D95),
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
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
    );
  }

  Widget _buildMetricTile(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$count회",
            style: GoogleFonts.anton(
              fontSize: 18,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}