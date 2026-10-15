import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/signup_screen.dart';
import '../widgets/common_snack_bar.dart';
import '/services/api_service.dart';
import 'main_holder.dart';
import '../dtos/login_request.dart';
import '../dtos/login_response.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

/// 로그인 페이지
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 컨트롤러 해제
  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  // 로그인 처리 함수
  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (_idController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      CommonSnackBar.show(
        context,
        message: "아이디와 비밀번호를 입력해주세요.",
        type: SnackBarType.info,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final LoginResponse? response = await ApiService().loginUser(
        LoginRequest(
          username: _idController.text,
          password: _passwordController.text,
        ),
      );

      if (!mounted) return;

      if (response != null && response.token.isNotEmpty) {
        context.read<UserProvider>().setUser(
          UserModel(
            id: 0,
            username: _idController.text,
            name: response.name.isNotEmpty
                ? response.name
                : _idController.text,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainHolder(),
          ),
        );
      } else {
        CommonSnackBar.show(
          context,
          message: "로그인 실패: 아이디 또는 비밀번호를 확인하세요.",
          type: SnackBarType.error,
        );
      }
    } catch (error) {
      if (!mounted) return;

      CommonSnackBar.show(
        context,
        message: "로그인 중 오류가 발생했습니다. 다시 시도해주세요.",
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

                  // 1. 브랜드 로고 & 아이콘 영역
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
                      color: Color(0xFF0F172A),
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

                  // 5. 메인 로그인 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                      child: _isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
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

                  // 7. [임시] 개발자 테스트 모드 버튼 (더미 유저 상태 유지)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        // 💡 테스트 진입 시 더미 유저 세팅 (필요시)
                        context.read<UserProvider>().setUser(UserModel.dummy());
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