class SquatData {
  final double waistAngle;
  final double thighAngle;
  final String status;        // 화면에 띄울 피드백 메시지
  final String currentState;  // 실시간 엔진 상태 (STAND, GOING_DOWN, FULL_SQUAT)

  // 통계용 카운터 데이터
  final int totalCount;       // 전체 완료 스쿼트 횟수
  final int successCount;     // 정상 스쿼트 횟수
  final int waistErrorCount;  // 허리 과숙임 오류 횟수
  final int depthErrorCount;  // 얕은 깊이 오류 횟수
  final int fastRepCount;     // 빠른 수행 오류 횟수

  SquatData({
    required this.waistAngle,
    required this.thighAngle,
    this.status = "준비",
    this.currentState = "STAND",
    this.totalCount = 0,
    this.successCount = 0,
    this.waistErrorCount = 0,
    this.depthErrorCount = 0,
    this.fastRepCount = 0,
  });

  // 다음 상태를 편하게 복사-생성하기 위한 복사 헬퍼 메서드
  SquatData copyWith({
    double? waistAngle,
    double? thighAngle,
    String? status,
    String? currentState,
    int? totalCount,
    int? successCount,
    int? waistErrorCount,
    int? depthErrorCount,
    int? fastRepCount,
  }) {
    return SquatData(
      waistAngle: waistAngle ?? this.waistAngle,
      thighAngle: thighAngle ?? this.thighAngle,
      status: status ?? this.status,
      currentState: currentState ?? this.currentState,
      totalCount: totalCount ?? this.totalCount,
      successCount: successCount ?? this.successCount,
      waistErrorCount: waistErrorCount ?? this.waistErrorCount,
      depthErrorCount: depthErrorCount ?? this.depthErrorCount,
      fastRepCount: fastRepCount ?? this.fastRepCount,
    );
  }
}