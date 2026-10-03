import 'package:flutter/material.dart';
import '../models/squat_model.dart';
import 'package:app/services/squat_analyzer_service.dart';
import '../utils/low_pass_filter.dart';
import '../models/squat_record.dart';
import '../services/database_helper.dart';

class SquatProvider with ChangeNotifier {
  // ================================================================
  // 화면에 그릴 상태 데이터
  // ================================================================
  SquatData _data = SquatData(
    waistAngle: 0.0,
    thighAngle: 0.0,
  );

  SquatData get data => _data;

  // ================================================================
  // 로컬 운동 기록
  // ================================================================
  List<SquatRecord> _localRecords = [];
  List<SquatRecord> get localRecords => _localRecords;

  // ================================================================
  // 스쿼트 분석 서비스
  // ================================================================
  final SquatAnalyzerService _analyzer = SquatAnalyzerService();
  SquatAnalyzerService get analyzer => _analyzer;

  // ================================================================
  // 기준점(영점) 벡터
  // ================================================================
  List<double>? _baseWaistVec;
  List<double>? _baseThighVec;

  // ================================================================
  // 로우 패스 필터
  // alpha가 낮을수록 더 부드럽지만 반응이 느려짐
  // ================================================================
  final LowPassFilter _waistFilter = LowPassFilter(alpha: 0.15);
  final LowPassFilter _thighFilter = LowPassFilter(alpha: 0.15);

  // ================================================================
  // 데이터 수신 상태
  // ================================================================
  bool _isReading = false;
  bool get isReading => _isReading;

  // ================================================================
  // 운동 시작
  // ================================================================
  void startReading() {
    _isReading = true;

    // 기존 영점 제거
    // 다음으로 들어오는 데이터를 새로운 영점으로 사용
    _baseWaistVec = null;
    _baseThighVec = null;

    // 이전 필터 상태 초기화
    _waistFilter.reset();
    _thighFilter.reset();

    // 이전에 진행 중이던 스쿼트 상태 초기화
    _analyzer.resetCurrentRepFlags();
  }

  // ================================================================
  // 블루투스 연결 해제
  // ================================================================
  void stopReadingOnDisconnect() {
    _isReading = false;
    _baseWaistVec = null;
    _baseThighVec = null;

    // 필터 초기화
    _waistFilter.reset();
    _thighFilter.reset();

    // 진행 중이던 스쿼트 상태 초기화
    _analyzer.resetCurrentRepFlags();

    _updateState(
      waist: 0.0,
      thigh: 0.0,
      status: "⚠️ 블루투스 연결이 끊어졌습니다. 재연결을 기다리는 중...",
    );
  }

  // ================================================================
  // 블루투스 원본 데이터 처리
  // ================================================================
  void updateRawData(
      List<double> currentW,
      List<double> currentT,
      ) {
    if (!_isReading) return;

    // ==============================================================
    // 1. 영점 포착
    // ==============================================================
    if (_baseWaistVec == null || _baseThighVec == null) {
      _baseWaistVec = currentW;
      _baseThighVec = currentT;

      _updateState(
        status: "영점 세팅 완료!",
      );

      return;
    }

    try {
      // ============================================================
      // 2. 기준 벡터와 현재 벡터 사이의 상대 각도 계산
      // ============================================================
      double rawWAngle = _analyzer.calculateRelativeAngle(
        _baseWaistVec!,
        currentW,
      );

      double rawTAngle = _analyzer.calculateRelativeAngle(
        _baseThighVec!,
        currentT,
      );

      // ============================================================
      // 3. 로우 패스 필터 적용
      // ============================================================
      double cleanWAngle = _waistFilter.filter(rawWAngle);
      double cleanTAngle = _thighFilter.filter(rawTAngle);

      // ============================================================
      // 4. 스쿼트 분석
      //
      // 여기서 Analyzer가:
      // - 허리 과숙임
      // - 얕은 깊이
      // - 빠른 수행
      //
      // 을 각각 독립적으로 판정한다.
      // ============================================================
      _data = _analyzer.analyze(
        _data,
        cleanWAngle,
        cleanTAngle,
      );

      notifyListeners();
    } catch (e) {
      print(
        "🚨 상대 각도 연산 및 자세 분석 도중 예외 발생: $e",
      );
    }
  }

  // ================================================================
  // 운동 카운트 및 피드백 통계만 초기화
  //
  // 영점과 연결 상태는 유지
  // ================================================================
  void resetCountersOnly() {
    _analyzer.resetCurrentRepFlags();

    _data = _data.copyWith(
      successCount: 0,
      waistErrorCount: 0,
      depthErrorCount: 0,
      fastRepCount: 0,
      status: "운동 기록 초기화",
      currentState: "STAND",
    );

    notifyListeners();
  }

  // ================================================================
  // 전체 상태 리셋
  // ================================================================
  void reset() {
    _isReading = false;

    _baseWaistVec = null;
    _baseThighVec = null;

    // 필터 상태 초기화
    _waistFilter.reset();
    _thighFilter.reset();

    // Analyzer 상태 초기화
    _analyzer.resetCurrentRepFlags();

    _data = SquatData(
      waistAngle: 0.0,
      thighAngle: 0.0,
      status: "정지됨",
    );

    notifyListeners();
  }

  // ================================================================
  // 내부 상태 갱신 헬퍼
  // ================================================================
  void _updateState({
    double? waist,
    double? thigh,
    String? status,
  }) {
    _data = _data.copyWith(
      waistAngle: waist,
      thighAngle: thigh,
      status: status,
    );

    notifyListeners();
  }

  // ================================================================
  // 현재 운동 세션 기록 저장
  // ================================================================
  Future<bool> saveCurrentSessionRecord() async {
    // 의미 있는 운동 기록이 없는 경우 저장하지 않음
    if (_data.successCount == 0 &&
        _data.waistErrorCount == 0 &&
        _data.depthErrorCount == 0 &&
        _data.fastRepCount == 0) {
      print("⚠️ 스쿼트 수행 기록이 없어 저장을 스킵합니다.");
      return false;
    }

    try {
      // SquatData → SquatRecord 변환
      final record = SquatRecord.fromSquatData(_data);

      // SQLite DB에 저장
      final savedId =
      await DatabaseHelper.instance.insertRecord(record);

      print(
        "💾 스쿼트 기록이 DB에 성공적으로 저장되었습니다! "
            "(Record ID: $savedId)",
      );

      // 저장 후 현재 카운터만 초기화
      // 연결 및 영점은 유지
      resetCountersOnly();

      // 최신 기록 다시 불러오기
      await loadLocalRecords();

      return true;
    } catch (e) {
      print("❌ DB 저장 중 에러 발생: $e");
      return false;
    }
  }

  // ================================================================
  // 로컬 DB 전체 운동 기록 불러오기
  // ================================================================
  Future<void> loadLocalRecords() async {
    _localRecords =
    await DatabaseHelper.instance.getAllRecords();

    notifyListeners();
  }

  // ================================================================
  // 로컬 운동 기록 전체 삭제
  // ================================================================
  Future<void> clearLocalRecords() async {
    await DatabaseHelper.instance.deleteAllRecords();

    _localRecords = [];

    notifyListeners();
  }

  // ================================================================
  // 테스트용 더미 기록 생성
  // ================================================================
  Future<void> generateDummyRecords() async {
    try {
      // 더미 데이터 생성
      await DatabaseHelper.instance.insertDummyRecords();

      // 최신 데이터 다시 불러오기
      await loadLocalRecords();

      print(
        "🧪 더미 데이터 30개 생성 완료 및 홈 화면 UI 갱신 방송 송출!",
      );
    } catch (e) {
      print("❌ 더미 데이터 생성 중 에러 발생: $e");
    }
  }
}