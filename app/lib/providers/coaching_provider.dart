import 'package:flutter/material.dart';
import '../dtos/aggregate_coaching_request.dart';
import '../dtos/coaching_response.dart';
import '../dtos/squat_workout_response.dart';
import '../services/api_service.dart';

/// AI 코칭 메세지 및 서버 데이터 관리 Provider
class CoachingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<SquatWorkoutResponse> _serverRecords = [];
  CoachingResponse? _latestCoaching;

  // 1. 일반 서버 조회/초기화용 상태 (가벼운 인디케이터)
  bool _isFetching = false;

  // 2. AI 분석 요청 전용 상태 (6초 몰입형 풀스크린 로딩)
  bool _isAiAnalyzing = false;

  String? _errorMessage;

  // 메인 화면 탭 제어용 (0: 기록/운동 탭, 1: AI 코칭 탭)
  int _currentTabIndex = 0;

  List<SquatWorkoutResponse> get serverRecords => _serverRecords;
  CoachingResponse? get latestCoaching => _latestCoaching;

  // 상태 Getters
  bool get isFetching => _isFetching;
  bool get isAiAnalyzing => _isAiAnalyzing;

  // 기존 코드와의 호환성을 위한 통합 getter (둘 중 하나라도 로딩 중이면 true)
  bool get isLoading => _isFetching || _isAiAnalyzing;

  String? get errorMessage => _errorMessage;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // 서버 DB에 저장된 사용자의 스쿼트 기록 목록 조회 (일반 조회 -> isFetching 사용)
  Future<void> fetchServerRecords() async {
    _setFetching(true);

    try {
      final records = await _apiService.getSquatRecords();
      if (records != null) {
        _serverRecords = records;
        _errorMessage = null;
      } else {
        _errorMessage = "서버 기록을 불러오지 못했습니다.";
      }
    } catch (e) {
      _errorMessage = "서버 연결 오류: $e";
    } finally {
      _setFetching(false);
    }
  }

  // 단일 기록 AI 코칭 요청 (AI 분석 -> isAiAnalyzing + 6초 타이머 사용)
  Future<bool> requestSingleCoaching(String uuid) async {
    _setAiAnalyzing(true);

    try {
      // API 요청과 6초 타이머를 병렬로 대기
      final results = await Future.wait([
        _apiService.getSingleCoaching(uuid),
        Future.delayed(const Duration(seconds: 6)), // 최소 대기 시간
      ]);

      final response = results[0] as CoachingResponse?;

      if (response != null) {
        _latestCoaching = response;
        _errorMessage = null;
        _setAiAnalyzing(false);
        return true;
      } else {
        _errorMessage = "단일 코칭 데이터를 불러오지 못했습니다.";
        _setAiAnalyzing(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "코칭 요청 중 오류가 발생했습니다: $e";
      _setAiAnalyzing(false);
      return false;
    }
  }

  // 다중 / 조건별 집계 AI 코칭 요청 (AI 분석 -> isAiAnalyzing + 6초 타이머 사용)
  Future<bool> requestAggregateCoaching(AggregateCoachingRequest request) async {
    _setAiAnalyzing(true);

    try {
      // API 요청과 6초 타이머를 병렬로 대기
      final results = await Future.wait([
        _apiService.getAggregateCoaching(request),
        Future.delayed(const Duration(seconds: 6)), // 최소 대기 시간
      ]);

      final response = results[0] as CoachingResponse?;

      if (response != null) {
        _latestCoaching = response;
        _errorMessage = null;
        _setAiAnalyzing(false);
        return true;
      } else {
        _errorMessage = "종합 코칭 데이터를 불러오지 못했습니다.";
        _setAiAnalyzing(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "종합 코칭 요청 중 오류가 발생했습니다: $e";
      _setAiAnalyzing(false);
      return false;
    }
  }

  // 일반 데이터 조회 로딩 상태 변경 메서드
  void _setFetching(bool fetching) {
    _isFetching = fetching;
    if (fetching) _errorMessage = null;
    notifyListeners();
  }

  // AI 분석 요청 로딩 상태 변경 메서드
  void _setAiAnalyzing(bool analyzing) {
    _isAiAnalyzing = analyzing;
    if (analyzing) _errorMessage = null;
    notifyListeners();
  }

  void resetCoaching() {
    _latestCoaching = null;
    _errorMessage = null;
    notifyListeners();
  }
}