import 'package:app/screens/signup_screen.dart';
import 'package:app/screens/squat_screen.dart';
import 'package:flutter/material.dart';
import '/services/api_service.dart';
import 'main_holder.dart';

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

  // 로그인 처리 함수
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

    // ApiService를 통해 서버로 로그인 검증 요청
    bool isSuccess = await ApiService().loginUser(
      _idController.text,
      _passwordController.text,
    );

    if (isSuccess) {
      // 로그인 성공 시 메인 화면으로 이동하며 로그인 화면은 스택에서 제거
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainHolder()), // MainHolder
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인 실패: 아이디 또는 비밀번호를 확인하세요.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "HEALTH COACH", // 로고 수정 필요
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 40),

            // 아이디 입력 창
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            //비밀번호 입력 창
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),

            //로그인 버튼
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("로그인", style: TextStyle(fontSize: 18)),
            ),

            // 회원가입 버튼
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text("아직 계정이 없으신가요? 회원가입"),
            ),
            const SizedBox(height: 15),

            // [임시] 서버 없이 바로 스쿼트 화면(혹은 MainHolder)으로 진입
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SquatScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.developer_mode, color: Colors.orange),
              label: const Text("서버 없이 테스트 모드 진입"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
