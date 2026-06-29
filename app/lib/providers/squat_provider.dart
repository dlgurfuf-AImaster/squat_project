import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/squat_model.dart';
import 'package:app/services/squat_analyzer.dart';

class SquatProvider with ChangeNotifier {
  // 화면에 그릴 상태 데이터 계층 분리
  SquatData _data = SquatData(waistAngle: 0.0, thighAngle: 0.0);
  SquatData get data => _data;

  final SquatAnalyzer _analyzer = SquatAnalyzer();
  SquatAnalyzer get analyzer => _analyzer;

  List<double>? _baseWaistVec; // 기준점 허리벡터
  List<double>? _baseThighVec; // 기준점 허벅지벡터

  // 전체 초기화 메소드
  void reset() {
    _analyzer.reset();
    _baseWaistVec = null;
    _baseThighVec = null;
    _updateState(waist: 0.0, thigh: 0.0, count: 0, status: "바르게 서서 스쿼트를 시작하세요.");
  }

  // 영점 조절
  void calibrate(List<double> wVec, List<double> tVec) {
    _baseWaistVec = wVec;
    _baseThighVec = tVec;
    _analyzer.reset();
    _updateState(status: "영점 조절 완료! 시작하세요.");
  }

  // 블루투스(또는 Mocking)로부터 오는 데이터를 받아 가공하는 순수 비즈니스 로직
  void updateRawData(List<double> currentW, List<double> currentT) {
    // 아직 영점이 안 잡혔으면 최초 데이터를 영점으로 강제 세팅
    if (_baseWaistVec == null || _baseThighVec == null) {
      calibrate(currentW, currentT);
      return;
    }

    // 상대 각도 계산 및 분석
    double wAngle = _calculateRelativeAngle(_baseWaistVec!, currentW);
    double tAngle = _calculateRelativeAngle(_baseThighVec!, currentT);
    String analysisResult = _analyzer.analyze(wAngle, tAngle);

    String newStatus = analysisResult.isNotEmpty ? analysisResult : _data.status;

    _updateState(
      waist: wAngle,
      thigh: tAngle,
      count: _analyzer.successCount,
      status: newStatus,
    );
  }

  // 상태를 갱신하여 UI를 새로 그리는 메서드
  void _updateState({double? waist, double? thigh, int? count, String? status}) {
    _data = SquatData(
      waistAngle: waist ?? _data.waistAngle,
      thighAngle: thigh ?? _data.thighAngle,
      count: count ?? _data.count,
      status: status ?? _data.status,
    );
    notifyListeners(); // 스쿼트 운동 화면 새로고침 신호
  }

  // 상대 각도 계산 수학 로직
  double _calculateRelativeAngle(List<double> base, List<double> current) {
    double dotProduct = base[0] * current[0] + base[1] * current[1] + base[2] * current[2];
    double magnitude = sqrt(base[0] * base[0] + base[1] * base[1] + base[2] * base[2]) *
        sqrt(current[0] * current[0] + current[1] * current[1] + current[2] * current[2]);
    return acos((dotProduct / magnitude).clamp(-1.0, 1.0)) * (180.0 / pi);
  }

  // 🌟 테스트용 가상 센서 생성기(Mocking)
  void startMocking() {
    reset();
    int tick = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      tick++;
      double factor = (sin(tick * 0.1).abs());
      List<double> virtualThighVec = [10.0 * (1 - factor), 3.0 * factor, -10.0 * factor];
      List<double> virtualWaistVec = [10.0 * (1 - factor * 0.3), 1.0 * factor * 0.3, -3.0 * factor * 0.3];

      updateRawData(virtualWaistVec, virtualThighVec);
    });
  }
}