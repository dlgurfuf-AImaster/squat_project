class LowPassFilter {
  final double alpha; // 0.0 ~ 1.0 (낮을수록 부드럽지만 반응이 느려짐)
  double _filteredValue = 0.0;
  bool _isFirstValue = true;

  LowPassFilter({required this.alpha});

  /// 원시(Raw) 수치를 넣어 필터링된 수치를 반환
  double filter(double rawValue) {
    if (_isFirstValue) {
      _filteredValue = rawValue;
      _isFirstValue = false;
    } else {
      _filteredValue = (_filteredValue * (1.0 - alpha)) + (rawValue * alpha);
    }
    return _filteredValue;
  }

  /// 필터 내부 상태 초기화
  void reset() {
    _isFirstValue = true;
    _filteredValue = 0.0;
  }
}