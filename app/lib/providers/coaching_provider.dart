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
  bool _isLoading = false;
  String? _errorMessage;

  // 메인 화면 탭 제어용 (0: 기록/운동 탭, 1: AI 코칭 탭)
  int _currentTabIndex = 0;

  List<SquatWorkoutResponse> get serverRecords => _serverRecords;
  CoachingResponse? get latestCoaching => _latestCoaching;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // 서버 DB에 저장된 사용자의 스쿼트 기록 목록 조회
  Future<void> fetchServerRecords() async {
    _setLoading(true);

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
      _setLoading(false);
    }
  }

  // 단일 기록 AI 코칭 요청
  Future<bool> requestSingleCoaching(int workoutId) async {
    _setLoading(true);

    try {
      final response = await _apiService.getSingleCoaching(workoutId);

      if (response != null) {
        _latestCoaching = response;
        _errorMessage = null; // 💡 성공 시 이전 에러 메시지 초기화
        _setLoading(false);
        return true;
      } else {
        _errorMessage = "단일 코칭 데이터를 불러오지 못했습니다.";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // 💡 네트워크 단절 등 통신 예외 처리
      _errorMessage = "코칭 요청 중 오류가 발생했습니다: $e";
      _setLoading(false);
      return false;
    }
  }

  // 다중 / 조건별 집계 AI 코칭 요청
  Future<bool> requestAggregateCoaching(AggregateCoachingRequest request) async {
    _setLoading(true);

    try {
      final response = await _apiService.getAggregateCoaching(request);

      if (response != null) {
        _latestCoaching = response;
        _errorMessage = null;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = "종합 코칭 데이터를 불러오지 못했습니다.";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = "종합 코칭 요청 중 오류가 발생했습니다: $e";
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }
}