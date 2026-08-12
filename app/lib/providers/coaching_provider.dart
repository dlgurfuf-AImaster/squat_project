import 'package:flutter/material.dart';
import '../dtos/aggregate_coaching_request.dart';
import '../dtos/coaching_response.dart';
import '../services/api_service.dart';

/// AI 코칭 메세지 유지 및 리디렉션 provider
class CoachingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  CoachingResponse? _latestCoaching;
  bool _isLoading = false;
  String? _errorMessage;

  // 메인 화면 탭 제어용 (0: 기록/운동 탭, 1: AI 코칭 탭 가정)
  // TODO 진짜 탭 매칭 필요
  int _currentTabIndex = 0;

  CoachingResponse? get latestCoaching => _latestCoaching;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  // 1. 단일 기록 AI 코칭 요청
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

  // 2. 다중 / 조건별 집계 AI 코칭 요청
  Future<bool> requestAggregateCoaching(AggregateCoachingRequest request) async {
    _setLoading(true);

    final response = await _apiService.getAggregateCoaching(request);

    if (response != null) {
      _latestCoaching = response;
      _setLoading(false);
      _redirectToCoachingTab(); // 코칭 탭으로 이동
      return true;
    } else {
      _errorMessage = "종합 코칭 데이터를 불러오지 못했습니다.";
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _redirectToCoachingTab() {
    // AI 코칭 탭(예: 1번 탭)으로 전환
    _currentTabIndex = 1;
    notifyListeners();
  }
}