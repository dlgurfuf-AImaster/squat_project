class SquatData {
  final double waistAngle;
  final double thighAngle;
  final String status;        // 화면에 띄울 피드백 메시지
  final String currentState;  // 실시간 엔진 상태 (STAND, GOING_DOWN, FULL_SQUAT)

  // 통계용 카운터 데이터 일원화
  final int successCount;
  final int waistErrorCount;   // 1번 오류: 상체 과숙임
  final int depthErrorCount;   // 2번 오류: 얕은 스쿼트
  final int goodMorningCount;  // 3번 오류: 굿모닝 스쿼트

  SquatData({
    required this.waistAngle,
    required this.thighAngle,
    this.status = "준비",
    this.currentState = "STAND",
    this.successCount = 0,
    this.waistErrorCount = 0,
    this.depthErrorCount = 0,
    this.goodMorningCount = 0,
  });

  // 다음 상태를 편하게 복사-생성하기 위한 가변 복사 헬퍼 메서드
  SquatData copyWith({
    double? waistAngle,
    double? thighAngle,
    String? status,
    String? currentState,
    int? successCount,
    int? waistErrorCount,
    int? depthErrorCount,
    int? goodMorningCount,
  }) {
    return SquatData(
      waistAngle: waistAngle ?? this.waistAngle,
      thighAngle: thighAngle ?? this.thighAngle,
      status: status ?? this.status,
      currentState: currentState ?? this.currentState,
      successCount: successCount ?? this.successCount,
      waistErrorCount: waistErrorCount ?? this.waistErrorCount,
      depthErrorCount: depthErrorCount ?? this.depthErrorCount,
      goodMorningCount: goodMorningCount ?? this.goodMorningCount,
    );
  }
}