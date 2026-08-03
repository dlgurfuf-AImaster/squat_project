import '../models/squat_model.dart'; // 기존 SquatData 참조

/// 내부에 영구 저장(DB)되는 스쿼트 한 세트의 최종 결과 기록 모델
class SquatRecord {
  final int? id;               // DB Primary Key (자동 증가)
  final DateTime date;         // 운동 종료/저장 시각
  final int successCount;     // 성공 횟수
  final int waistErrorCount;   // 숙임 오류 횟수
  final int depthErrorCount;   // 깊이 부족 오류 횟수
  final int goodMorningCount;  // 굿모닝 자세 오류 횟수

  SquatRecord({
    this.id,
    required this.date,
    required this.successCount,
    required this.waistErrorCount,
    required this.depthErrorCount,
    required this.goodMorningCount,
  });

  // 🌟 [핵심 1] 실시간 상태(SquatData)를 받아 저장용 객체로 즉시 변환하는 생성자
  factory SquatRecord.fromSquatData(SquatData data) {
    return SquatRecord(
      date: DateTime.now(),
      successCount: data.successCount,
      waistErrorCount: data.waistErrorCount,
      depthErrorCount: data.depthErrorCount,
      goodMorningCount: data.goodMorningCount,
    );
  }

  // 🌟 [핵심 2] SQLite DB 저장을 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'successCount': successCount,
      'waistErrorCount': waistErrorCount,
      'depthErrorCount': depthErrorCount,
      'goodMorningCount': goodMorningCount,
    };
  }

  // 🌟 [핵심 3] DB에서 읽어온 Map 데이터를 객체로 변환
  factory SquatRecord.fromMap(Map<String, dynamic> map) {
    return SquatRecord(
      id: map['id'],
      date: DateTime.parse(map['date']),
      successCount: map['successCount'],
      waistErrorCount: map['waistErrorCount'],
      depthErrorCount: map['depthErrorCount'],
      goodMorningCount: map['goodMorningCount'],
    );
  }
}