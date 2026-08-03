import 'dart:math';
import '../models/squat_model.dart';

class SquatAnalyzerService {
  // 튜닝 파라미터
  final double _startSquatThreshold = 40.0;       // 💡 [새 장벽] 최소 40도는 넘어야 스쿼트 시작으로 인정!
  final double _fullSquatThreshold = 85.0;        // 이 각도를 넘었어야 깊이 성공
  final double _completelyStandThreshold = 15.0;  // 이 각도 이하로 오면 무조건 '한 번의 스쿼트 완료'

  double _maxThighAngleInCurrentRep = 0.0;
  bool _isWaistErrorTriggered = false;
  bool _isGoodMorningErrorTriggered = false;
  bool _isCurrentlyExercising = false;

  SquatData analyze(SquatData previousData, double waistAngle, double thighAngle) {
    double cleanThigh = thighAngle.clamp(0.0, 180.0);
    double cleanWaist = waistAngle.clamp(0.0, 180.0);

    String message = previousData.status;
    int success = previousData.successCount;
    int waistErr = previousData.waistErrorCount;
    int depthErr = previousData.depthErrorCount;
    int gmErr = previousData.goodMorningCount;

    // --------------------------------------------------------
    // 1. [수정된 부분] 최소 40도를 넘어야만 '진짜 운동 시작'으로 인정
    // --------------------------------------------------------
    if (cleanThigh > _startSquatThreshold) {
      _isCurrentlyExercising = true; // 💡 40도 미만의 10~30도 찌꺼기 노이즈는 이 문을 못 통과합니다!
    }

    // 💡 이제 진짜 운동 중일 때만 실시간 데이터를 수집합니다.
    if (_isCurrentlyExercising) {
      // 실시간 허벅지 최고 깊이 기록
      if (cleanThigh > _maxThighAngleInCurrentRep) {
        _maxThighAngleInCurrentRep = cleanThigh;
      }

      // 내려갈 때 허리 실수의 기준도 최소 시작 각도(40도)보다는 클 때만 체크하도록 변경
      if (cleanWaist > 40.0 && _maxThighAngleInCurrentRep < _fullSquatThreshold) {
        _isWaistErrorTriggered = true;
      }
      // 올라올 때 허리 실수
      if (cleanWaist > 40.0 && _maxThighAngleInCurrentRep >= _fullSquatThreshold) {
        _isGoodMorningErrorTriggered = true;
      }

      message = "운동 진행 중... 현재 최대 깊이: ${_maxThighAngleInCurrentRep.toStringAsFixed(1)}도";
    }

    // --------------------------------------------------------
    // 2. [마침표] 유저가 확실하게 일어섰을 때 (15도 이하) 딱 1번만 정산!
    // --------------------------------------------------------
    // 💡 40도를 넘어서 '_isCurrentlyExercising'이 true가 되었던 정상적인 세션만 여기서 정산됩니다.
    if (cleanThigh <= _completelyStandThreshold && _isCurrentlyExercising) {
      bool hasAnyError = false;
      List<String> errorMessages = [];

      // ❌ [얕은 깊이 판정]
      // 40도는 넘겼지만(운동 시작 인정), 최종 최고 깊이가 85도에는 못 미친 경우!
      if (_maxThighAngleInCurrentRep < _fullSquatThreshold) {
        depthErr++;
        hasAnyError = true;
        errorMessages.add("얕은 깊이");
      }

      if (_isWaistErrorTriggered) {
        waistErr++;
        hasAnyError = true;
        errorMessages.add("내려갈 때 허리 숙임");
      }

      if (_isGoodMorningErrorTriggered) {
        gmErr++;
        hasAnyError = true;
        errorMessages.add("일어날 때 허리 무너짐");
      }

      if (!hasAnyError) {
        success++;
        message = "✨ 스쿼트 ${success}회 성공! 완벽합니다.";
      } else {
        message = "❌ 무효 (${errorMessages.join(', ')}) 최고 깊이: ${_maxThighAngleInCurrentRep.toStringAsFixed(1)}도";
      }

      // 🔥 정산이 끝났으니 공책 완전히 청소
      _maxThighAngleInCurrentRep = 0.0;
      _isWaistErrorTriggered = false;
      _isGoodMorningErrorTriggered = false;
      _isCurrentlyExercising = false;
    }

    return previousData.copyWith(
      waistAngle: cleanWaist,
      thighAngle: cleanThigh,
      status: message,
      successCount: success,
      waistErrorCount: waistErr,
      depthErrorCount: depthErr,
      goodMorningCount: gmErr,
    );
  }

  /// 현재 진행 중이던 1회성 스쿼트 임시 데이터를 강제로 청소합니다.
  void resetCurrentRepFlags() {
    _maxThighAngleInCurrentRep = 0.0;
    _isWaistErrorTriggered = false;
    _isGoodMorningErrorTriggered = false;
    _isCurrentlyExercising = false; // 💡 새 로직의 핵심 플래그도 함께 초기화!
  }

  /// 3차원 공간 상의 두 벡터 간 사이 각도를 구하는 수학 메서드
  double calculateRelativeAngle(List<double> base, List<double> current) {
    if (base.length < 3 || current.length < 3) return 0.0; // 데이터 누락 예외 방어

    double dotProduct = base[0] * current[0] + base[1] * current[1] + base[2] * current[2];
    double magnitude = sqrt(base[0] * base[0] + base[1] * base[1] + base[2] * base[2]) *
        sqrt(current[0] * current[0] + current[1] * current[1] + current[2] * current[2]);

    if (magnitude == 0) return 0.0; // 0 나누기 오류 방지
    return acos((dotProduct / magnitude).clamp(-1.0, 1.0)) * (180.0 / pi);
  }
}