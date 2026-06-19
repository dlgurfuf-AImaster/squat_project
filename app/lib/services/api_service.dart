import 'package:dio/dio.dart';

class ApiService {
  // 싱글톤 패턴 적용 (앱 전체에서 하나의 dio 인스턴스만 공유하여 메모리 절약)
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio();

  // ip 주소 계속 바뀜에 유의
  // 서버 ip 주소 입력할 것, ip 주소가 계속 바뀌니까 고려해야 함
  final String _baseUrl = "http://192.168.219.139:9000/api";

  ApiService._internal() {
    _dio.options.baseUrl = _baseUrl;

    // 연결 실패 유예 시간 조정
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  /// 회원가입 요청 함수
  Future<bool> registerUser(String name, String username, String password) async {
    try {
      // 서버의 ("/user/signup") 과 매핑
      final response = await _dio.post(
        "/user/signup",
        data: {
          "name": name,
          "username": username,
          "password": password,
        },
      );

      // 서버가 성공 코드를 반환했는지 확인
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("회원가입 통신 에러: $e");
      return false;
    }
  }

  /// 로그인 요청 함수
  Future<bool> loginUser(String username, String password) async {
    try {
      // ("/user/login") 과 매핑
      final response = await _dio.post(
        "/user/login",
        data: {
          "username": username,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        // TODO: 나중에 서버가 돌려준 JWT 토큰을 저장하는 로직이 들어올 곳입니다.
        return true;
      }
      return false;
    } catch (e) {
      print("로그인 통신 에러: $e");
      return false;
    }
  }
}