class SquatAnalyzer {
  // 현재 유저의 운동 상태를 정의
  String _currentState = "STAND";

  String get currentState => _currentState;

  // 통계용 카운터 변수들
  int _successCount = 0; // 성공 개수
  int _waistErrorCount = 0; // 허리 과숙임 개수
  int _depthErrorCount = 0; // 얕은 스쿼트 개수
  int _goodMorningCount = 0; // 엉덩이 선행 개수

  // 외부에서 값을 읽어갈 수 있도록 getter
  int get successCount => _successCount;

  int get waistErrorCount => _waistErrorCount; // 1번 오류
  int get depthErrorCount => _depthErrorCount; // 2번 오류
  int get goodMorningCount => _goodMorningCount; // 3번 오류

  // 튜닝 파라미터? 튜닝 포인트!
  // 1. 시작 각도 설정
  final double _startSquatThreshold = 30.0;

  // 2. 정석 스쿼트 깊이 정도
  final double _fullSquatThreshold = 85.0;

  // 3. 완전히 일어남 인정 각도
  final double _getUpThreshold = 30.0;

  // 4. 허리가 과도하게 숙여졌을 때, 허리 각도
  final double _waistLeanMax = 40.0;

  // 얕은 스쿼트를 잡아내기 위해 가장 깊이 앉은 각도 기록 (문제가 생길 수 있을 듯)
  double _maxThighAngleInCurrentRep = 0.0;

  /// 상태 및 카운트 초기화 (영점 잡을 때 호출)
  void reset() {
    _currentState = "STAND";
    _successCount = 0;
    _waistErrorCount = 0;
    _depthErrorCount = 0;
    _goodMorningCount = 0;
    _maxThighAngleInCurrentRep = 0.0;
  }

  /// [핵심 알고리즘] 3대 불량 자세 및 정상 스쿼트 판별 로직
  String analyze(double waistAngle, double thighAngle) {
    // 1. 센서 노이즈로 인해 각도가 마이너스로 튀거나 역전되는 현상 방지
    double cleanThigh = thighAngle.clamp(0.0, 180.0);
    double cleanWaist = waistAngle.clamp(0.0, 180.0);

    String message = "";

    switch (_currentState) {
      case "STAND":
        _maxThighAngleInCurrentRep = 0.0;

        if (cleanThigh > _startSquatThreshold) {
          _currentState = "GOING_DOWN";
          message = "내려가는 중... 더 깊게 앉으세요!";
        } else {
          message = "바르게 서서 스쿼트를 시작하세요.";
        }
        break;

      case "GOING_DOWN":
        // 실시간 내려간 각도 중 가장 깊은 각도 갱신
        if (cleanThigh > _maxThighAngleInCurrentRep) {
          _maxThighAngleInCurrentRep = cleanThigh;
        }

        // [1번 오류 감지]
        if (cleanWaist > _waistLeanMax) {
          _waistErrorCount++;
          message = "❌ 경고: 허리가 너무 숙여졌습니다! (상체 세우기)";
          _currentState = "STAND"; // 상태 리셋
          break;
        }

        if (cleanThigh >= _fullSquatThreshold) {
          _currentState = "FULL_SQUAT";
          message = "좋습니다! 그대로 천천히 일어나세요.";
        }
        // [2번 오류 감지] 너무 일찍 일어나 버린 경우 처리
        else if (cleanThigh < _getUpThreshold) {
          if (_maxThighAngleInCurrentRep < _fullSquatThreshold) {
            _depthErrorCount++;
            message = "❌ 무효: 너무 얕게 앉았습니다! 더 깊게 앉으세요.";
          }
          _currentState = "STAND";
        }
        break;

      case "FULL_SQUAT":
        if (cleanThigh <= _getUpThreshold) {
          // [3번 오류 감지] 허벅지는 일어났는데, 허리는 여전히 숙여져 있는 경우
          if (cleanWaist > _waistLeanMax) {
            _goodMorningCount++;
            message = "❌ 무효: 일어날 때 상체가 뒤늦게 펴졌습니다 (허리 부담 위험)!";
            _currentState = "STAND";
          } else {
            _successCount++;
            message = "✨ 스쿼트 ${_successCount}회 성공! 아주 좋습니다.";
            _currentState = "STAND";
          }
        } else {
          // 유지 메세지
          message = "좋습니다! 끝까지 무릎을 펴고 일어나세요.";
        }
        break;
    }
    return message;
  }
}
