class AggregateCoachingRequest {
  final List<String>? workoutUuids;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? recent30Days;

  AggregateCoachingRequest({
    this.workoutUuids,
    this.startDate,
    this.endDate,
    this.recent30Days,
  });

  factory AggregateCoachingRequest.byUuids(List<String> uuids) {
    return AggregateCoachingRequest(workoutUuids: uuids);
  }

  factory AggregateCoachingRequest.byDateRange(DateTime start, DateTime end) {
    return AggregateCoachingRequest(startDate: start, endDate: end);
  }

  factory AggregateCoachingRequest.recent30Days() {
    return AggregateCoachingRequest(recent30Days: true);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (workoutUuids != null && workoutUuids!.isNotEmpty) {
      json["workoutUuids"] = workoutUuids;
    } else if (startDate != null && endDate != null) {
      json["startDate"] = startDate!.toIso8601String().split('T')[0];
      json["endDate"] = endDate!.toIso8601String().split('T')[0];
    } else if (recent30Days == true) {
      json["recent30Days"] = true;
    }

    return json;
  }
}