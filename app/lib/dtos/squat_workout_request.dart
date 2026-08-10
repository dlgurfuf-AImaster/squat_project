import '../models/squat_record.dart';

class SquatWorkoutRequest {
  final int successCount;
  final int waistErrorCount;
  final int depthErrorCount;
  final int goodMorningCount;
  final DateTime recordTime;

  SquatWorkoutRequest({
    required this.successCount,
    required this.waistErrorCount,
    required this.depthErrorCount,
    required this.goodMorningCount,
    required this.recordTime,
  });

  factory SquatWorkoutRequest.fromRecord(SquatRecord record) {
    return SquatWorkoutRequest(
      successCount: record.successCount,
      waistErrorCount: record.waistErrorCount,
      depthErrorCount: record.depthErrorCount,
      goodMorningCount: record.goodMorningCount,
      recordTime: record.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "successCount": successCount,
      "waistErrorCount": waistErrorCount,
      "depthErrorCount": depthErrorCount,
      "goodMorningCount": goodMorningCount,
      "recordTime": recordTime.toIso8601String().split('.')[0], // yyyy-MM-ddTHH:mm:ss
    };
  }
}