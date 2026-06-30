import 'dart:math';
import 'dart:async'; // startMocking 타이머용
import 'package:flutter/material.dart';
import '../models/squat_model.dart';
import 'package:app/services/squat_analyzer.dart';

class SquatProvider with ChangeNotifier {
  // 화면에 그릴 상태 데이터 계층 (상태값 캡슐화)
  SquatData _data = SquatData(waistAngle: 0.0, thighAngle: 0.0);
  SquatData get data => _data;

  final SquatAnalyzer _analyzer = SquatAnalyzer();
  SquatAnalyzer get analyzer => _analyzer;

  List<double>? _baseWaistVec; // 기준점(영점) 허리 벡터
  List<double>? _baseThighVec; // 기준점(영점) 허벅지 벡터

  bool _isReading = false;
  bool get isReading => _isReading;

  /// 운동 시작 버튼 클릭 시 호출: 수신 창구를 개방하고 영점 세팅을 준비합니다.
  void startReading() {
    _isReading = true;
    _baseWaistVec = null; // 기존 영점을 비워 차기 유입 데이터를 영점으로 잡도록 유도
    _baseThighVec = null;
  }

  /// 블루투스 연결 해제 시 강제 셧다운 안전장치
  void stopReadingOnDisconnect() {
    _isReading = false;
    _baseWaistVec = null;
    _baseThighVec = null;

    _updateState(
      waist: 0.0,
      thigh: 0.0,
      status: "⚠️ 블루투스 연결이 끊어졌습니다. 재연결을 기다리는 중...",
    );
  }

  /// 블루투스로부터 들어오는 3차원 원본 데이터를 받아 각도를 가공하는 코어 비즈니스 로직
  void updateRawData(List<double> currentW, List<double> currentT) {
    if (!_isReading) return;

    // [영점 포착] 버튼이 눌린 후 처음 유입된 싱싱한 패킷을 기준점으로 고정
    if (_baseWaistVec == null || _baseThighVec == null) {
      _baseWaistVec = currentW;
      _baseThighVec = currentT;
      _updateState(status: "🎯 영점 세팅 완료! 스쿼트를 시작하세요.");
      return;
    }

    try {
      // 3차원 공간 벡터 삼각함수 연산을 통한 상대 각도 추출
      double wAngle = _calculateRelativeAngle(_baseWaistVec!, currentW);
      double tAngle = _calculateRelativeAngle(_baseThighVec!, currentT);

      // 자세 분석기를 통한 스쿼트 성공/실패 판별
      String analysisResult = _analyzer.analyze(wAngle, tAngle);
      String newStatus = analysisResult.isNotEmpty ? analysisResult : _data.status;

      _updateState(
        waist: wAngle,
        thigh: tAngle,
        count: _analyzer.successCount,
        status: newStatus,
      );
    } catch (e) {
      print("🚨 상대 각도 연산 및 자세 분석 도중 예외 발생: $e");
    }
  }

  /// 순수 운동 카운트 및 피드백 통계만 초기화 (영점/각도는 유지)
  void resetCountersOnly() {
    _analyzer.reset();
    _data = SquatData(
      waistAngle: _data.waistAngle,
      thighAngle: _data.thighAngle,
      count: 0,
      status: "📊 운동 기록이 초기화되었습니다. 계속 운동해 주세요!",
    );
    notifyListeners();
  }

  /// 전역 상태 전면 리셋 (초기 공장 상태)
  void reset() {
    _isReading = false;
    _baseWaistVec = null;
    _baseThighVec = null;
    _analyzer.reset();
    _data = SquatData(
      waistAngle: 0.0,
      thighAngle: 0.0,
      count: 0,
      status: "아두이노 연결 후 운동 시작을 눌러주세요.",
    );
    notifyListeners();
  }

  /// 내부 상태 객체 일괄 갱신 헬퍼 메서드
  void _updateState({double? waist, double? thigh, int? count, String? status}) {
    _data = SquatData(
      waistAngle: waist ?? _data.waistAngle,
      thighAngle: thigh ?? _data.thighAngle,
      count: count ?? _data.count,
      status: status ?? _data.status,
    );
    notifyListeners(); // UI 계층 실시간 새로고침 전파
  }

  /// 3차원 공간 상의 두 벡터 간 사이 각도를 구하는 수학 메서드
  double _calculateRelativeAngle(List<double> base, List<double> current) {
    if (base.length < 3 || current.length < 3) return 0.0; // 데이터 누락 예외 방어

    double dotProduct = base[0] * current[0] + base[1] * current[1] + base[2] * current[2];
    double magnitude = sqrt(base[0] * base[0] + base[1] * base[1] + base[2] * base[2]) *
        sqrt(current[0] * current[0] + current[1] * current[1] + current[2] * current[2]);

    if (magnitude == 0) return 0.0; // 0 나누기 오류 방지
    return acos((dotProduct / magnitude).clamp(-1.0, 1.0)) * (180.0 / pi);
  }

  /// [테스트용] 가상 센서 패킷 제너레이터 (Mocking)
  void startMocking() {
    reset();
    _isReading = true;
    int tick = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isReading) {
        timer.cancel();
        return;
      }
      tick++;
      double factor = (sin(tick * 0.1).abs());
      List<double> virtualThighVec = [10.0 * (1 - factor), 3.0 * factor, -10.0 * factor];
      List<double> virtualWaistVec = [10.0 * (1 - factor * 0.3), 1.0 * factor * 0.3, -3.0 * factor * 0.3];

      updateRawData(virtualWaistVec, virtualThighVec);
    });
  }
}