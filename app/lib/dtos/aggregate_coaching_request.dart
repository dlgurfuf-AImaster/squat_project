class AggregateCoachingRequest {
  final List<String> workoutUuids;

  AggregateCoachingRequest({
    required this.workoutUuids,
  });

  factory AggregateCoachingRequest.byUuids(List<String> uuids) {
    return AggregateCoachingRequest(
      workoutUuids: uuids,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "workoutUuids": workoutUuids,
    };
  }
}