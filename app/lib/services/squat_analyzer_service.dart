import 'dart:math';
import '../models/squat_model.dart';

class SquatAnalyzerService {
  final double _startSquatThreshold = 40.0;
  final double _fullSquatThreshold = 85.0;
  final double _completelyStandThreshold = 15.0;
  final double _ascentTolerance = 1.0;

  double _maxThighAngleInCurrentRep = 0.0;
  double _previousThighAngle = 0.0;

  bool _isWaistErrorTriggered = false;
  bool _isFastRepErrorTriggered = false;
  bool _isCurrentlyExercising = false;
  bool _isAscending = false;

  SquatData analyze(
      SquatData previousData,
      double waistAngle,
      double thighAngle,
      ) {
    double cleanThigh = thighAngle.clamp(0.0, 180.0);
    double cleanWaist = waistAngle.clamp(0.0, 180.0);

    String message = previousData.status;
    int success = previousData.successCount;
    int waistErr = previousData.waistErrorCount;
    int depthErr = previousData.depthErrorCount;
    int fastRepErr = previousData.fastRepCount;

    // 1. 스쿼트 시작 감지
    if (cleanThigh > _startSquatThreshold) {
      if (!_isCurrentlyExercising) {
        _previousThighAngle = cleanThigh;
      }

      _isCurrentlyExercising = true;
    }

    if (_isCurrentlyExercising) {
      // 현재까지의 최고 깊이 기록
      if (cleanThigh > _maxThighAngleInCurrentRep) {
        _maxThighAngleInCurrentRep = cleanThigh;
      }

      // 충분한 깊이에 도달한 이후 허벅지 각도가 감소하면 상승 시작
      if (_maxThighAngleInCurrentRep >= _fullSquatThreshold &&
          cleanThigh < _previousThighAngle - _ascentTolerance) {
        _isAscending = true;
      }

      // 하강 중 충분한 깊이에 도달하기 전에 허리가 과도하게 숙여진 경우
      if (!_isAscending &&
          _maxThighAngleInCurrentRep < _fullSquatThreshold &&
          cleanWaist > 40.0) {
        _isWaistErrorTriggered = true;
      }

      // 충분한 깊이에 도달한 후 상승하면서 상체가 먼저 무너지는 경우
      if (_isAscending &&
          !_isWaistErrorTriggered &&
          cleanWaist > 40.0) {
        _isFastRepErrorTriggered = true;
      }

      message =
      "운동 진행 중... 현재 최대 깊이: ${_maxThighAngleInCurrentRep.toStringAsFixed(1)}도";

      _previousThighAngle = cleanThigh;
    }

    // 2. 완전히 일어선 시점에 한 회 정산
    if (cleanThigh <= _completelyStandThreshold &&
        _isCurrentlyExercising) {
      bool hasAnyError = false;
      List<String> errorMessages = [];

      // 충분한 깊이에 도달하지 못한 경우
      if (_maxThighAngleInCurrentRep < _fullSquatThreshold) {
        depthErr++;
        hasAnyError = true;
        errorMessages.add("얕은 깊이");
      }

      // 하강 중 허리 과숙임
      if (_isWaistErrorTriggered) {
        waistErr++;
        hasAnyError = true;
        errorMessages.add("허리 과숙임");
      }

      // 최고 깊이 이후 상승 중 상체 선행
      if (_isFastRepErrorTriggered) {
        fastRepErr++;
        hasAnyError = true;
        errorMessages.add("상체 선행");
      }

      if (!hasAnyError) {
        success++;
        message = "✨ 스쿼트 ${success}회 성공! 완벽합니다.";
      } else {
        message =
        "❌ 무효 (${errorMessages.join(', ')}) 최고 깊이: ${_maxThighAngleInCurrentRep.toStringAsFixed(1)}도";
      }

      _maxThighAngleInCurrentRep = 0.0;
      _previousThighAngle = 0.0;
      _isWaistErrorTriggered = false;
      _isFastRepErrorTriggered = false;
      _isCurrentlyExercising = false;
      _isAscending = false;
    }

    return previousData.copyWith(
      waistAngle: cleanWaist,
      thighAngle: cleanThigh,
      status: message,
      successCount: success,
      waistErrorCount: waistErr,
      depthErrorCount: depthErr,
      fastRepCount: fastRepErr,
    );
  }

  void resetCurrentRepFlags() {
    _maxThighAngleInCurrentRep = 0.0;
    _previousThighAngle = 0.0;
    _isWaistErrorTriggered = false;
    _isFastRepErrorTriggered = false;
    _isCurrentlyExercising = false;
    _isAscending = false;
  }

  double calculateRelativeAngle(
      List<double> base,
      List<double> current,
      ) {
    if (base.length < 3 || current.length < 3) return 0.0;

    double dotProduct =
        base[0] * current[0] +
            base[1] * current[1] +
            base[2] * current[2];

    double magnitude =
        sqrt(
          base[0] * base[0] +
              base[1] * base[1] +
              base[2] * base[2],
        ) *
            sqrt(
              current[0] * current[0] +
                  current[1] * current[1] +
                  current[2] * current[2],
            );

    if (magnitude == 0) return 0.0;

    return acos(
      (dotProduct / magnitude).clamp(-1.0, 1.0),
    ) *
        (180.0 / pi);
  }
}