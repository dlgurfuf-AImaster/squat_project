class SquatData {
  final double waistAngle;
  final double thighAngle;
  final int count;
  final String status;

  SquatData({
    required this.waistAngle,
    required this.thighAngle,
    this.count = 0, //TODO 이곳으로 카운트 변수들 옮겨야 할 듯함
    this.status = "준비",
  });
}