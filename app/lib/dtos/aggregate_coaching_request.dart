class AggregateCoachingRequest {
  final List<int>? workoutIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? recent30Days;

  AggregateCoachingRequest({
    this.workoutIds,
    this.startDate,
    this.endDate,
    this.recent30Days,
  });

  factory AggregateCoachingRequest.byIds(List<int> ids) {
    return AggregateCoachingRequest(workoutIds: ids);
  }

  factory AggregateCoachingRequest.byDateRange(DateTime start, DateTime end) {
    return AggregateCoachingRequest(startDate: start, endDate: end);
  }

  factory AggregateCoachingRequest.recent30Days() {
    return AggregateCoachingRequest(recent30Days: true);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (workoutIds != null && workoutIds!.isNotEmpty) {
      json["workoutIds"] = workoutIds;
    } else if (startDate != null && endDate != null) {
      json["startDate"] = startDate!.toIso8601String().split('T')[0];
      json["endDate"] = endDate!.toIso8601String().split('T')[0];
    } else if (recent30Days == true) {
      json["recent30Days"] = true;
    }

    return json;
  }
}