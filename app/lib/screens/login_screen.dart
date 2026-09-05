import 'package:flutter/material.dart';
import 'package:app/screens/signup_screen.dart';
import '/services/api_service.dart';
import 'main_holder.dart';
import '../dtos/login_request.dart';
import '../dtos/login_response.dart';
import '../theme/app_theme.dart';

/// 로그인 페이지
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 컨트롤러 해제
  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 로그인 처리 함수 (비즈니스 로직 유지)
  void _handleLogin() async {
    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("아이디와 비밀번호를 입력해주세요.")));
      return;
    }

    // 비동기로 일단 띄움
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("로그인 중...")));

    // LoginRequest DTO 생성 및 ApiService 호출 방식 변경
    final LoginResponse? response = await ApiService().loginUser(
      LoginRequest(
        username: _idController.text,
        password: _passwordController.text,
      ),
    );

    // LoginResponse 객체 검증
    if (response != null && response.token.isNotEmpty) {
      if (!mounted) return;
      // 로그인 성공 시 메인 화면으로 이동하며 로그인 화면은 스택에서 제거
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainHolder()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인 실패: 아이디 또는 비밀번호를 확인하세요.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 바탕 터치 시 키보드 닫기
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // 1. 브랜드 로고 & 아이콘 영역 (HomeScreen 상단 헤더와 통일감)
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.primarySky,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primarySky.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(1, 0),
                          child: Image.asset(
                            'assets/images/main_icon.png',
                            width: 68,
                            height: 68,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. 앱 타이틀 & 서브 타이틀
                  const Text(
                    "SquatMate",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A), // 딥 슬레이트
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "AI 코칭과 함께하는 스마트 운동 파트너",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 3. 아이디 입력 창
                  _buildTextField(
                    controller: _idController,
                    labelText: "아이디",
                    hintText: "아이디를 입력하세요",
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),

                  // 4. 비밀번호 입력 창
                  _buildTextField(
                    controller: _passwordController,
                    labelText: "비밀번호",
                    hintText: "비밀번호를 입력하세요",
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 28),

                  // 5. 메인 로그인 버튼 (PrimarySky + 그림자 효과)
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySky,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.transparent,
                    ).copyWith(
                      elevation: WidgetStateProperty.all(0),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primarySky.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        "로그인",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. 회원가입 가이딩 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "아직 계정이 없으신가요?",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          "회원가입",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primarySky,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 7. [임시] 개발자 테스트 모드 버튼 (깔끔한 칩 스타일)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainHolder(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.developer_mode_rounded, size: 18, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Text(
                              "서버 없이 테스트 모드 진입",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 공통 입력 텍스트 필드 위젯
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            labelText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primarySky, width: 1.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}