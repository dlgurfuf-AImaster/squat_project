import 'package:flutter/material.dart';
import '/services/api_service.dart';

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

  // 유효성 검사
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

    // ApiService를 통해 서버로 데이터 전송
    bool isSuccess = await ApiService().registerUser(
      _nameController.text,
      _idController.text,
      _passwordController.text,
    );

    if (isSuccess) {
      _showSnackBar("회원가입이 완료되었습니다! 로그인해주세요.");
      if (!mounted) return; // 비동기 처리 후 context 안전 검사
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
      appBar: AppBar(title: const Text("회원가입"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // 이름 입력창
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름 / 닉네임',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),

            // 아이디 입력창
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // 비밀번호 입력창
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),

            // 비밀번호 확인 입력 창
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 32),

            // 회원가입 완료 버튼
            ElevatedButton(
              onPressed: _handleSignup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("가입하기", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
