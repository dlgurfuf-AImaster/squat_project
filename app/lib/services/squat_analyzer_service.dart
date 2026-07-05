import 'dart:math';
import '../models/squat_model.dart';

class SquatAnalyzerService {
  // 튜닝 파라미터 고정
  final double _startSquatThreshold = 30.0;
  final double _fullSquatThreshold = 85.0;
  final double _getUpThreshold = 30.0;
  final double _waistLeanMax = 40.0;

  double _maxThighAngleInCurrentRep = 0.0;

  void resetMaxAngle() {
    _maxThighAngleInCurrentRep = 0.0;
  }

  /// [핵심 알고리즘]
  /// 이전 SquatData 상태를 받아와서, 새로운 각도로 계산된 '새로운 SquatData'를 반환합니다.
  SquatData analyze(SquatData previousData, double waistAngle, double thighAngle) {
    double cleanThigh = thighAngle.clamp(0.0, 180.0);
    double cleanWaist = waistAngle.clamp(0.0, 180.0);

    // 기본적으로 이전 카운트 상태를 그대로 복사해옵니다.
    String nextState = previousData.currentState;
    String message = previousData.status;
    int success = previousData.successCount;
    int waistErr = previousData.waistErrorCount;
    int depthErr = previousData.depthErrorCount;
    int gmErr = previousData.goodMorningCount;

    switch (nextState) {
      case "STAND":
        _maxThighAngleInCurrentRep = 0.0;
        if (cleanThigh > _startSquatThreshold) {
          nextState = "GOING_DOWN";
          message = "내려가는 중... 더 깊게 앉으세요!";
        } else {
          message = "바르게 서서 스쿼트를 시작하세요.";
        }
        break;

      case "GOING_DOWN":
        if (cleanThigh > _maxThighAngleInCurrentRep) {
          _maxThighAngleInCurrentRep = cleanThigh;
        }

        // [1번 오류 감지]
        if (cleanWaist > _waistLeanMax) {
          waistErr++;
          message = "❌ 경고: 허리가 너무 숙여졌습니다! (상체 세우기)";
          nextState = "STAND";
          break;
        }

        if (cleanThigh >= _fullSquatThreshold) {
          nextState = "FULL_SQUAT";
          message = "좋습니다! 그대로 천천히 일어나세요.";
        }
        // [2번 오류 감지]
        else if (cleanThigh < _getUpThreshold) {
          if (_maxThighAngleInCurrentRep < _fullSquatThreshold) {
            depthErr++;
            message = "❌ 무효: 너무 얕게 앉았습니다! 더 깊게 앉으세요.";
          }
          nextState = "STAND";
        }
        break;

      case "FULL_SQUAT":
        if (cleanThigh <= _getUpThreshold) {
          // [3번 오류 감지]
          if (cleanWaist > _waistLeanMax) {
            gmErr++;
            message = "❌ 무효: 일어날 때 상체가 뒤늦게 펴졌습니다 (허리 부담 위험)!";
            nextState = "STAND";
          } else {
            success++;
            message = "✨ 스쿼트 ${success}회 성공! 아주 좋습니다.";
            nextState = "STAND";
          }
        } else {
          message = "좋습니다! 끝까지 무릎을 펴고 일어나세요.";
        }
        break;
    }

    // 💡 최종 계산된 알맹이들을 copyWith를 통해 완전 새 스냅샷 객체로 조립하여 반환!
    return previousData.copyWith(
      waistAngle: cleanWaist,
      thighAngle: cleanThigh,
      status: message,
      currentState: nextState,
      successCount: success,
      waistErrorCount: waistErr,
      depthErrorCount: depthErr,
      goodMorningCount: gmErr,
    );
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
