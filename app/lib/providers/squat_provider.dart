import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../models/squat_model.dart';
import 'package:app/services/squat_analyzer.dart';
import 'package:app/services/MyBluetoothService.dart';

/// 중심 컨트롤 provider
class SquatProvider with ChangeNotifier {
  SquatData _data = SquatData(waistAngle: 0.0, thighAngle: 0.0);
  SquatData get data => _data;

  final SquatAnalyzer _analyzer = SquatAnalyzer();
  SquatAnalyzer get analyzer => _analyzer;

  final MyBluetoothService _bluetoothService = MyBluetoothService();
  List<double>? _baseWaistVec; // 기준점 허리벡터
  List<double>? _baseThighVec; // 기준점 허벅지벡터


  // 전체 초기화 메소드
  void reset() {
    _analyzer.reset(); // 스쿼트 분석기 초기화 (status = STAND)
    // 기준점 초기화
    _baseWaistVec = null;
    _baseThighVec = null;
    // UI 초기화
    _updateState(
      waist: 0.0,
      thigh: 0.0,
      count: 0,
      status: "바르게 서서 스쿼트를 시작하세요.",
    );
  }

  // 영점 조절
  void calibrate(List<double> wVec, List<double> tVec) {
    _baseWaistVec = wVec;
    _baseThighVec = tVec;
    _analyzer.reset();
    _updateState(status: "영점 조절 완료! 시작하세요.");
  }

  // 아두이노를 켜고 운동 시작 메서드
  void startBluetoothWorkout() async {
    _updateState(status: "아두이노 연결 시도 중...");

    // 아두이노를 찾아 연결 시도
    await _bluetoothService.connectToArduino("BT05", (waistVec, thighVec) {
      // 영점 잡기 버튼을 누르는 순간에 영점이 저장 ?? 영점 잡는 시점 수정 필요!, 영점 버튼 만들기
      if (_baseWaistVec == null || _baseThighVec == null) {
        calibrate(waistVec, thighVec);
      }
      // 데이터 전송
      updateRawData(waistVec, thighVec);
    });
  }

  // 블루투스로부터 오는 데이터 수신처
  void updateRawData(List<double> currentW, List<double> currentT) {
    if (_baseWaistVec == null || _baseThighVec == null) return;

    // 상대 각도 계산
    double wAngle = _calculateRelativeAngle(_baseWaistVec!, currentW);
    double tAngle = _calculateRelativeAngle(_baseThighVec!, currentT);
    // 각도 분석 후 결과 얻기
    String analysisResult = _analyzer.analyze(wAngle, tAngle);

    String newStatus = analysisResult.isNotEmpty
        ? analysisResult
        : _data.status;

    // UI 동기화
    _updateState(
      waist: wAngle,
      thigh: tAngle,
      count: _analyzer.successCount,
      status: newStatus,
    );
  }

  // 상태를 갱신하여 UI를 새로 그리는 메서드
  void _updateState({
    double? waist,
    double? thigh,
    int? count,
    String? status,
  }) {
    _data = SquatData(
      waistAngle: waist ?? _data.waistAngle,
      thighAngle: thigh ?? _data.thighAngle,
      count: count ?? _data.count,
      status: status ?? _data.status,
    );
    notifyListeners(); // squat_screen한테 정보 전달
  }

  // =========================================================================
  // 🎯 [축별 가중치 필터 세팅] 각 축의 민감도를 0.0 ~ 1.0 사이로 조절하세요!
  // =========================================================================
  // 예: X축 위주로 움직이고 Y, Z축이 노이즈라면 Y와 Z의 가중치를 확 낮춥니다.
  double _weightX = 0.5;
  double _weightY = 0.1; // 노이즈가 심한 축은 0.1 ~ 0.3 등으로 깎아버리기
  double _weightZ = 0.1;
  // =========================================================================

  /// 📐 [필터 적용] 가중치가 반영된 상대 각도 계산 수학 로직
  double _calculateRelativeAngle(List<double> base, List<double> current) {
    // 1. 기준(base) 벡터와 현재(current) 벡터 각각에 축별 가중치(Filter) 적용
    double bX = base[0] * _weightX;
    double bY = base[1] * _weightY;
    double bZ = base[2] * _weightZ;

    double cX = current[0] * _weightX;
    double cY = current[1] * _weightY;
    double cZ = current[2] * _weightZ;

    // 2. 가중치가 적용된 새로운 성분으로 내적(Dot Product) 계산
    double dotProduct = (bX * cX) + (bY * cY) + (bZ * cZ);

    // 3. 가중치가 적용된 벡터들의 크기(Magnitude) 계산
    double magnitude = sqrt(bX * bX + bY * bY + bZ * bZ) *
        sqrt(cX * cX + cY * cY + cZ * cZ);

    // 분모가 0이 되어 NaN 에러가 나는 것을 방지
    if (magnitude == 0) return 0.0;

    // 4. 최종 사이각 계산 및 아크코사인 변환
    return acos((dotProduct / magnitude).clamp(-1.0, 1.0)) * (180.0 / pi);
  }


  // 테스트용 (나중에 삭제예정)
  void startMocking() {
    // 1. (서 있을 때: X=10, Y=0, Z=0)
    calibrate([10.0, 0.0, 0.0], [10.0, 0.0, 0.0]);

    int tick = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      tick++;

      // 2. 0.0(서 있음) ~ 1.0(완전히 앉음) 사이를 왕복하는 계수
      double factor = (sin(tick * 0.1).abs());

      // 3. 측정하신 데이터 기반 가상 허벅지(Thigh) 벡터 생성
      // 서 있을 때(10, 0, 0) -> 앉았을 때(0, 3, -10)
      List<double> virtualThighVec = [
        10.0 * (1 - factor) + (0.0 * factor), // X축 변화
        0.0 * (1 - factor) + (3.0 * factor), // Y축 변화
        0.0 * (1 - factor) + (-10.0 * factor), // Z축 변화
      ];

      // 4. 허리는 허벅지보다 덜 움직이도록 설정 (예: factor의 30%만 반영)
      double wFactor = factor * 0.3;
      List<double> virtualWaistVec = [
        10.0 * (1 - wFactor) + (0.0 * wFactor),
        0.0 * (1 - wFactor) + (1.0 * wFactor),
        0.0 * (1 - wFactor) + (-3.0 * wFactor),
      ];

      // 5. 로직 업데이트
      updateRawData(virtualWaistVec, virtualThighVec);
    });
  }
}
