import 'package:flutter/material.dart';
import '../models/squat_model.dart';
import 'package:app/services/squat_analyzer_service.dart';
import '../utils/low_pass_filter.dart';
import '../models/squat_record.dart';
import '../services/database_helper.dart';

class SquatProvider with ChangeNotifier {
  // 화면에 그릴 상태 데이터 계층 (상태값 캡슐화)
  SquatData _data = SquatData(waistAngle: 0.0, thighAngle: 0.0);
  SquatData get data => _data;

  final SquatAnalyzerService _analyzer = SquatAnalyzerService();
  SquatAnalyzerService get analyzer => _analyzer;

  List<double>? _baseWaistVec; // 기준점(영점) 허리 벡터
  List<double>? _baseThighVec; // 기준점(영점) 허벅지 벡터

  // 허리와 허벅지 독립 필터 인스턴스 멤버 변수로 추가 (alpha = 0.15)
  final LowPassFilter _waistFilter = LowPassFilter(alpha: 0.15);
  final LowPassFilter _thighFilter = LowPassFilter(alpha: 0.15);

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

    // 연결 해제 시 필터 초기화
    _waistFilter.reset();
    _thighFilter.reset();

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
      double rawWAngle = _analyzer.calculateRelativeAngle(_baseWaistVec!, currentW);
      double rawTAngle = _analyzer.calculateRelativeAngle(_baseThighVec!, currentT);

      // 로우 패스 필터를 통과시켜 노이즈가 제거된 부드러운 각도 획득
      double cleanWAngle = _waistFilter.filter(rawWAngle);
      double cleanTAngle = _thighFilter.filter(rawTAngle);

      _data = _analyzer.analyze(_data, cleanWAngle, cleanTAngle);
      notifyListeners();
    } catch (e) {
      print("🚨 상대 각도 연산 및 자세 분석 도중 예외 발생: $e");
    }
  }

  /// 순수 운동 카운트 및 피드백 통계만 초기화 (영점/각도는 유지)
  void resetCountersOnly() {
    _analyzer.resetCurrentRepFlags();
    _data = _data.copyWith(
      successCount: 0,
      waistErrorCount: 0,
      depthErrorCount: 0,
      goodMorningCount: 0,
      status: "📊 운동 기록이 초기화되었습니다. 계속 운동해 주세요!",
      currentState: "STAND",
    );
    notifyListeners();
  }

  /// 전역 상태 전면 리셋 (초기 공장 상태)
  void reset() {
    _isReading = false;
    _baseWaistVec = null;
    _baseThighVec = null;

    // 전면 리셋 시 필터 상태도 함께 초기화
    _waistFilter.reset();
    _thighFilter.reset();

    _analyzer.resetCurrentRepFlags();
    _data = SquatData(
      waistAngle: 0.0,
      thighAngle: 0.0,
      status: "정지됨",
    );
    notifyListeners();
  }

  /// 내부 상태 객체 일괄 갱신 헬퍼 메서드
  void _updateState({double? waist, double? thigh, String? status}) {
    _data = _data.copyWith(
      waistAngle: waist,
      thighAngle: thigh,
      status: status,
    );
    notifyListeners(); // UI 계층 실시간 새로고침 전파
  }

  /// 현재 진행된 운동 세션의 기록을 로컬 DB에 저장하는 메서드
  Future<bool> saveCurrentSessionRecord() async {
    // 1. 유효성 검사: 성공 횟수와 에러 횟수가 모두 0이면 저장하지 않음 (의미 없는 빈 기록 방지)
    if (_data.successCount == 0 &&
        _data.waistErrorCount == 0 &&
        _data.depthErrorCount == 0 &&
        _data.goodMorningCount == 0) {
      print("⚠️ 스쿼트 수행 기록이 없어 저장을 스킵합니다.");
      return false;
    }

    try {
      // 2. SquatData 객체에서 SquatRecord 객체로 변환
      final record = SquatRecord.fromSquatData(_data);

      // 3. DatabaseHelper를 통해 SQLite DB에 Insert
      final savedId = await DatabaseHelper.instance.insertRecord(record);
      print("💾 스쿼트 기록이 DB에 성공적으로 저장되었습니다! (Record ID: $savedId)");

      // 4. 저장 완료 후 현재 카운터만 0으로 초기화 (연결은 유지)
      resetCountersOnly();
      notifyListeners();

      return true; // 저장 성공 반환
    } catch (e) {
      print("❌ DB 저장 중 에러 발생: $e");
      return false;
    }
  }
}