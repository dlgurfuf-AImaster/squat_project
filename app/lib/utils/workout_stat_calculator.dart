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

    final todayIndex = now.weekday - 1;

    final monday = today.subtract(Duration(days: todayIndex));
    final nextMonday = monday.add(const Duration(days: 7));

    final List<int> dailyCounts = List.filled(7, 0);
    int weeklyTotal = 0;
    int maxSingle = 0;

    final Set<DateTime> activeDates = {};

    for (final r in records) {
      final recordDate = r.date;
      final normalizedDate = DateTime(
        recordDate.year,
        recordDate.month,
        recordDate.day,
      );

      if (r.totalCount > 0) {
        activeDates.add(normalizedDate);
      }

      if (!recordDate.isBefore(monday) &&
          recordDate.isBefore(nextMonday)) {
        final dayIdx = recordDate.weekday - 1;

        dailyCounts[dayIdx] += r.totalCount;
        weeklyTotal += r.totalCount;

        if (r.totalCount > maxSingle) {
          maxSingle = r.totalCount;
        }
      }
    }

    int streak = 0;
    DateTime checkDate = activeDates.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));

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