import 'package:flutter/material.dart';
import '/services/api_service.dart';
import '../dtos/signup_request.dart';
import '../theme/app_theme.dart';

/// 회원가입 페이지
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // 유효성 검사 (비즈니스 로직 100% 유지)
  void _handleSignup() async {
    if (_idController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      _showSnackBar("모든 필드를 입력해주세요.");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("비밀번호가 일치하지 않습니다.");
      return;
    }

    _showSnackBar("회원가입 요청 중...");

    // SignupRequest DTO 생성 및 전송
    bool isSuccess = await ApiService().registerUser(
      SignupRequest(
        name: _nameController.text,
        username: _idController.text,
        password: _passwordController.text,
      ),
    );

    if (isSuccess) {
      _showSnackBar("회원가입이 완료되었습니다! 로그인해주세요.");
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      _showSnackBar("회원가입에 실패했습니다. 서버 상태를 확인하세요.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "회원가입",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 바탕 터치 시 키보드 닫기
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 환영 인사 및 안내 헤더
                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "SquatMate와 함께 건강한 운동 습관을 만들어봐요.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),

                // 2. 이름/닉네임 입력
                _buildTextField(
                  controller: _nameController,
                  labelText: "이름 / 닉네임",
                  hintText: "사용하실 이름을 입력하세요",
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 18),

                // 3. 아이디 입력
                _buildTextField(
                  controller: _idController,
                  labelText: "아이디",
                  hintText: "사용하실 아이디를 입력하세요",
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 18),

                // 4. 비밀번호 입력
                _buildTextField(
                  controller: _passwordController,
                  labelText: "비밀번호",
                  hintText: "비밀번호를 입력하세요",
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 18),

                // 5. 비밀번호 확인 입력
                _buildTextField(
                  controller: _confirmPasswordController,
                  labelText: "비밀번호 확인",
                  hintText: "비밀번호를 다시 한번 입력하세요",
                  prefixIcon: Icons.verified_user_outlined,
                  obscureText: true,
                ),
                const SizedBox(height: 36),

                // 6. 가입하기 버튼 (PrimarySky + 글로우 그림자)
                ElevatedButton(
                  onPressed: _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primarySky,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                      "가입하기",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 공통 입력 텍스트 필드 위젯 (LoginScreen과 동일 패턴)
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