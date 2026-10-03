class SquatWorkoutResponse {
  final int id;
  final String uuid;
  final int totalCount;
  final int successCount;
  final int waistErrorCount;
  final int depthErrorCount;
  final int fastRepCount;
  final String? coachingMessage;
  final String recordTime;

  SquatWorkoutResponse({
    required this.id,
    required this.uuid,
    required this.totalCount,
    required this.successCount,
    required this.waistErrorCount,
    required this.depthErrorCount,
    required this.fastRepCount,
    this.coachingMessage,
    required this.recordTime,
  });

  factory SquatWorkoutResponse.fromJson(Map<String, dynamic> json) {
    return SquatWorkoutResponse(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      totalCount: json['totalCount'] ?? 0,
      successCount: json['successCount'] ?? 0,
      waistErrorCount: json['waistErrorCount'] ?? 0,
      depthErrorCount: json['depthErrorCount'] ?? 0,
      fastRepCount: json['fastRepCount'] ?? 0,
      coachingMessage: json['coachingMessage'],
      recordTime: json['recordTime'] ?? '',
    );
  }
}