class CoachingResponse {
  final String coachingType;
  final int totalSessions;
  final int totalSuccessCount;
  final int totalWaistErrorCount;
  final int totalDepthErrorCount;
  final int totalGoodMorningCount;
  final String coachingMessage;

  CoachingResponse({
    required this.coachingType,
    required this.totalSessions,
    required this.totalSuccessCount,
    required this.totalWaistErrorCount,
    required this.totalDepthErrorCount,
    required this.totalGoodMorningCount,
    required this.coachingMessage,
  });

  factory CoachingResponse.fromJson(Map<String, dynamic> json) {
    return CoachingResponse(
      coachingType: json['coachingType'] ?? 'SINGLE',
      totalSessions: json['totalSessions'] ?? 1,
      totalSuccessCount: json['totalSuccessCount'] ?? 0,
      totalWaistErrorCount: json['totalWaistErrorCount'] ?? 0,
      totalDepthErrorCount: json['totalDepthErrorCount'] ?? 0,
      totalGoodMorningCount: json['totalGoodMorningCount'] ?? 0,
      coachingMessage: json['coachingMessage'] ?? '코칭 메시지가 없습니다.',
    );
  }
}