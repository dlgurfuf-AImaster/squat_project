import 'dart:math';
import '../models/squat_model.dart';

class SquatAnalyzerService {
  // 튜닝 파라미터
  final double _startSquatThreshold = 40.0;
  final double _fullSquatThreshold = 85.0;
  final double _completelyStandThreshold = 15.0;
  final double _minimumRepDuration = 3.0; // 빠른 수행 판정 시간. 현재 3초

  // 현재 스쿼트의 최고 깊이
  double _maxThighAngleInCurrentRep = 0.0;

  // 현재 스쿼트 상태
  bool _isWaistErrorTriggered = false;
  bool _isFastRepErrorTriggered = false;
  bool _isCurrentlyExercising = false;

  // 현재 스쿼트 시작 시간
  DateTime? _repStartTime;

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

    // ============================================================
    // 1. 스쿼트 시작 감지
    // ============================================================
    if (cleanThigh > _startSquatThreshold) {
      if (!_isCurrentlyExercising) {
        _isCurrentlyExercising = true;

        // 스쿼트 1회 시작 시간 기록
        _repStartTime = DateTime.now();
      }
    }

    // ============================================================
    // 2. 운동 진행 중 분석
    // ============================================================
    if (_isCurrentlyExercising) {
      // 현재까지 도달한 최대 깊이 기록
      if (cleanThigh > _maxThighAngleInCurrentRep) {
        _maxThighAngleInCurrentRep = cleanThigh;
      }

      // ------------------------------------------------------------
      // 허리 과숙임
      // 운동 중 어느 순간이라도 허리 각도가 40°를 초과하면
      // 해당 스쿼트에서 허리 과숙임 오류 발생
      // ------------------------------------------------------------
      if (cleanWaist > 40.0) {
        _isWaistErrorTriggered = true;
      }

      message =
      "운동 진행 중... 현재 최대 깊이: "
          "${_maxThighAngleInCurrentRep.toStringAsFixed(1)}도";
    }

    // ============================================================
    // 3. 완전히 일어선 시점에 한 회 정산
    // ============================================================
    if (cleanThigh <= _completelyStandThreshold &&
        _isCurrentlyExercising) {
      bool hasAnyError = false;
      List<String> errorMessages = [];

      // ------------------------------------------------------------
      // 수행 시간 계산
      // ------------------------------------------------------------
      double repDuration = 0.0;

      if (_repStartTime != null) {
        repDuration =
            DateTime.now().difference(_repStartTime!).inMilliseconds / 1000.0;
      }

      // ------------------------------------------------------------
      // 빠른 수행
      // 1회 수행 시간이 4초 미만이면 오류
      // ------------------------------------------------------------
      if (repDuration < _minimumRepDuration) {
        _isFastRepErrorTriggered = true;
      }

      // ------------------------------------------------------------
      // 얕은 깊이
      // 최대 허벅지 각도가 85°에 도달하지 못한 경우
      // ------------------------------------------------------------
      if (_maxThighAngleInCurrentRep < _fullSquatThreshold) {
        depthErr++;
        hasAnyError = true;
        errorMessages.add("얕은 깊이");
      }

      // ------------------------------------------------------------
      // 허리 과숙임
      // ------------------------------------------------------------
      if (_isWaistErrorTriggered) {
        waistErr++;
        hasAnyError = true;
        errorMessages.add("허리 과숙임");
      }

      // ------------------------------------------------------------
      // 빠른 수행
      // ------------------------------------------------------------
      if (_isFastRepErrorTriggered) {
        fastRepErr++;
        hasAnyError = true;
        errorMessages.add("빠른 수행");
      }

      // ------------------------------------------------------------
      // 최종 결과
      // ------------------------------------------------------------
      if (!hasAnyError) {
        success++;
        message = "✨ 스쿼트 ${success}회 성공! 완벽합니다.";
      } else {
        message =
        "❌ 무효 (${errorMessages.join(', ')}) "
            "최고 깊이: ${_maxThighAngleInCurrentRep.toStringAsFixed(1)}도 "
            "수행 시간: ${repDuration.toStringAsFixed(1)}초";
      }

      // ============================================================
      // 4. 현재 스쿼트 상태 초기화
      // ============================================================
      _maxThighAngleInCurrentRep = 0.0;
      _isWaistErrorTriggered = false;
      _isFastRepErrorTriggered = false;
      _isCurrentlyExercising = false;
      _repStartTime = null;
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

  // ================================================================
  // 현재 진행 중인 스쿼트 상태 초기화
  // ================================================================
  void resetCurrentRepFlags() {
    _maxThighAngleInCurrentRep = 0.0;
    _isWaistErrorTriggered = false;
    _isFastRepErrorTriggered = false;
    _isCurrentlyExercising = false;
    _repStartTime = null;
  }

  // ================================================================
  // 기준 벡터와 현재 벡터 사이의 상대 각도 계산
  // ================================================================
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
