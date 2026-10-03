import '../models/squat_record.dart';

class WorkoutWeeklyStats {
  final int streakDays;        // 연속 운동 일수 (Streak)
  final int weeklyTotalReps;   // 이번 주 총 횟수
  final int maxRepsInSingle;   // 역대 단일 세트 최고 횟수
  final List<int> dailyCounts; // 이번 주 월~일 (7개 항목) 수행 횟수
  final int todayIndex;        // 오늘 요일 인덱스 (월:0 ~ 일:6)

  WorkoutWeeklyStats({
    required this.streakDays,
    required this.weeklyTotalReps,
    required this.maxRepsInSingle,
    required this.dailyCounts,
    required this.todayIndex,
  });

  factory WorkoutWeeklyStats.calculate(List<SquatRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. 오늘 요일 인덱스 (DateTime.monday = 1 ... sunday = 7 -> index 0~6)
    final todayIndex = now.weekday - 1;

    // 2. 이번 주 월요일 00:00:00 ~ 일요일 23:59:59 시간 범위 계산
    final monday = today.subtract(Duration(days: todayIndex));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final List<int> dailyCounts = List.filled(7, 0);
    int weeklyTotal = 0;
    int maxSingle = 0;

    // 운동을 시행한 날짜 목록 (연속 일수 계산용)
    final Set<DateTime> activeDates = {};

    for (final r in records) {
      final recordDate = r.date;
      final normalizedDate = DateTime(recordDate.year, recordDate.month, recordDate.day);

      // 1세트 총 횟수 (성공 + 오류 전체 합산)
      final int totalReps = r.successCount + r.waistErrorCount + r.depthErrorCount + r.upperBodyLeadCount;

      if (totalReps > 0) {
        activeDates.add(normalizedDate);
        if (totalReps > maxSingle) maxSingle = totalReps;
      }

      // 이번 주(월~일)에 해당하는 기록인 경우
      if (recordDate.isAfter(monday.subtract(const Duration(seconds: 1))) &&
          recordDate.isBefore(sunday)) {
        final dayIdx = recordDate.weekday - 1; // 0(월) ~ 6(일)
        dailyCounts[dayIdx] += totalReps;
        weeklyTotal += totalReps;
      }
    }

    // 3. 연속 운동 일수(Streak) 계산 (오늘 또는 어제부터 시작해 소급)
    int streak = 0;
    DateTime checkDate = activeDates.contains(today) ? today : today.subtract(const Duration(days: 1));

    while (activeDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return WorkoutWeeklyStats(
      streakDays: streak,
      weeklyTotalReps: weeklyTotal,
      maxRepsInSingle: maxSingle,
      dailyCounts: dailyCounts,
      todayIndex: todayIndex,
    );
  }
}