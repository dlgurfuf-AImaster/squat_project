import '../models/squat_record.dart';

class SquatWorkoutRequest {
  final String uuid;
  final int successCount;
  final int waistErrorCount;
  final int depthErrorCount;
  final int fastRepCount;
  final DateTime recordTime;

  SquatWorkoutRequest({
    required this.uuid,
    required this.successCount,
    required this.waistErrorCount,
    required this.depthErrorCount,
    required this.fastRepCount,
    required this.recordTime,
  });

  factory SquatWorkoutRequest.fromRecord(SquatRecord record) {
    return SquatWorkoutRequest(
      uuid: record.uuid,
      successCount: record.successCount,
      waistErrorCount: record.waistErrorCount,
      depthErrorCount: record.depthErrorCount,
      fastRepCount: record.fastRepCount,
      recordTime: record.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      "successCount": successCount,
      "waistErrorCount": waistErrorCount,
      "depthErrorCount": depthErrorCount,
      "fastRepCount": fastRepCount,
      "recordTime": recordTime.toIso8601String().split('.')[0], // yyyy-MM-ddTHH:mm:ss
    };
  }
}