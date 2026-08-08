import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/squat_record.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 서버 IP 및 기본 URL (v1 경로 포함)
  final String _baseUrl = "http://192.168.219.102:9000/api/v1";

  ApiService._internal() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);
  }

  // --- 토큰 로컬 저장소 조작 헬퍼 --- (JWT 정보 저장)
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// 회원가입 요청 함수
  Future<bool> registerUser(String name, String username, String password) async {
    try {
      final response = await _dio.post(
        "/user/signup",
        data: {
          "name": name,
          "username": username,
          "password": password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("회원가입 통신 에러: $e");
      return false;
    }
  }

  /// 로그인 요청 함수 (토큰 저장 로직 추가)
  Future<bool> loginUser(String username, String password) async {
    try {
      final response = await _dio.post(
        "/user/login",
        data: {
          "username": username,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        // 서버 응답 구조에 맞춰 토큰 추출 (문자열 또는 JSON 형태)
        String? token;
        if (response.data is Map && response.data.containsKey('token')) {
          token = response.data['token'];
        } else if (response.data is String) {
          token = response.data;
        }

        if (token != null && token.isNotEmpty) {
          await _saveToken(token); // 로컬 암호화 저장소에 저장
          return true;
        }
      }
      return false;
    } catch (e) {
      print("로그인 통신 에러: $e");
      return false;
    }
  }

  /// 스쿼트 운동 기록 백엔드 전송 함수
  Future<bool> sendSquatRecord(SquatRecord record) async {
    try {
      final token = await getToken();

      if (token == null) {
        print("저장된 JWT 토큰이 없습니다.");
        return false;
      }

      final response = await _dio.post(
        "/squat/record",
        data: {
          "successCount": record.successCount,
          "waistErrorCount": record.waistErrorCount,
          "depthErrorCount": record.depthErrorCount,
          "goodMorningCount": record.goodMorningCount,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token", // JWT 토큰 헤더 전달
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("스쿼트 기록 전송 에러: $e");
      return false;
    }
  }
}