class SquatData {
  final double waistAngle;
  final double thighAngle;
  final int count;
  final String status;

  SquatData({
    required this.waistAngle,
    required this.thighAngle,
    this.count = 0,
    this.status = "준비",
  });
}