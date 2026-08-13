import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dtos/aggregate_coaching_request.dart';
import '../dtos/coaching_response.dart';
import '../dtos/login_request.dart';
import '../dtos/login_response.dart';
import '../dtos/signup_request.dart';
import '../dtos/squat_workout_request.dart';
import '../dtos/squat_workout_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final String _baseUrl = dotenv.get('BASE_URL');

  ApiService._internal() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
  }

  // --- 토큰 및 유저 정보 저장소 조작 헬퍼 ---
  Future<void> _saveAuthData(String token, String name) async {
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_name', value: name);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  /// 1. 회원가입 요청
  Future<bool> registerUser(SignupRequest request) async {
    try {
      final response = await _dio.post(
        "/user/signup",
        data: request.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("회원가입 통신 에러: $e");
      return false;
    }
  }

  /// 2. 로그인 요청 (토큰 및 사용자 이름 저장)
  Future<LoginResponse?> loginUser(LoginRequest request) async {
    try {
      final response = await _dio.post(
        "/user/login",
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final loginResponse = LoginResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (loginResponse.token.isNotEmpty) {
          await _saveAuthData(loginResponse.token, loginResponse.name);
          return loginResponse;
        }
      }
      return null;
    } catch (e) {
      print("로그인 통신 에러: $e");
      return null;
    }
  }

  /// 3. 스쿼트 운동 기록 백엔드 전송
  Future<SquatWorkoutResponse?> sendSquatRecord(
      SquatWorkoutRequest request,
      ) async {
    try {
      final token = await getToken();

      if (token == null) {
        print("저장된 JWT 토큰이 없습니다.");
        return null;
      }

      final response = await _dio.post(
        "/squat/record",
        data: request.toJson(),
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return SquatWorkoutResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      print("스쿼트 기록 전송 에러: $e");
      return null;
    }
  }

  /// 4. 단일 운동 기록 ID 기반 AI 코칭 요청
  Future<CoachingResponse?> getSingleCoaching(int workoutId) async {
    try {
      final token = await getToken();

      if (token == null) {
        print("저장된 JWT 토큰이 없습니다.");
        return null;
      }

      final response = await _dio.post(
        "/squat/coaching/single/$workoutId",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return CoachingResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      print("단일 코칭 요청 에러: $e");
      return null;
    }
  }

  /// 5. 집계 AI 코칭 요청 (개별 ID 선택 / 날짜 지정 / 최근 30일)
  Future<CoachingResponse?> getAggregateCoaching(
      AggregateCoachingRequest request,
      ) async {
    try {
      final token = await getToken();

      if (token == null) {
        print("저장된 JWT 토큰이 없습니다.");
        return null;
      }

      final requestMap = request.toJson();
      if (requestMap.isEmpty) {
        print("코칭 분석 조건이 선택되지 않았습니다.");
        return null;
      }

      final response = await _dio.post(
        "/squat/coaching/aggregate",
        data: requestMap,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return CoachingResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return null;
    } catch (e) {
      print("종합 코칭 요청 에러: $e");
      return null;
    }
  }

  /// 6. 서버 DB에 저장된 사용자의 스쿼트 기록 목록 조회
  Future<List<SquatWorkoutResponse>?> getSquatRecords() async {
    try {
      final token = await getToken();
      if (token == null) {
        print("저장된 JWT 토큰이 없습니다.");
        return null;
      }

      final response = await _dio.get(
        "/squat/records",
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = response.data;
        // 타입 안정성을 위해 명시적으로 Map<String, dynamic> 캐스팅 추가
        return rawList
            .map((json) => SquatWorkoutResponse.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print("❌ 서버 기록 조회 실패: $e");
    }
    return null;
  }

  /// 7. 서버 DB에 저장된 특정 스쿼트 기록 삭제 (UUID 기준)
  Future<bool> deleteSquatRecordByUuid(String uuid) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _dio.delete(
        "/squat/records/$uuid", // 💡 URL 경로에 UUID 전달
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("❌ 서버 기록 삭제 에러: $e");
      return false;
    }
  }
}