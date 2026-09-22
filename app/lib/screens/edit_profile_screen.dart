import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nicknameController;
  final FocusNode _focusNode = FocusNode();

  bool _isFocused = false;
  bool _isSaved = false;
  bool _isLoading = false;
  Timer? _savedTimer;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    _nicknameController = TextEditingController(text: user.name);

    _focusNode.addListener(_handleFocusChange);
    _nicknameController.addListener(_handleNicknameChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _nicknameController.removeListener(_handleNicknameChange);
    _nicknameController.dispose();
    _focusNode.dispose();
    _savedTimer?.cancel();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleNicknameChange() {
    if (_isSaved) {
      setState(() {
        _isSaved = false;
      });
    } else {
      setState(() {});
    }
  }

  // ── 저장 비즈니스 로직 ─────────────────────────────────────────────────────
  Future<void> _handleSave(UserModel currentUser) async {
    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty || newNickname == currentUser.name || _isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });

    final bool success = await ApiService().updateNickname(newNickname);

    if (!mounted) return;

    if (success) {
      context.read<UserProvider>().setUser(
        UserModel(
          id: currentUser.id,
          username: currentUser.username,
          name: newNickname,
        ),
      );

      setState(() {
        _isLoading = false;
        _isSaved = true;
      });

      _savedTimer?.cancel();
      _savedTimer = Timer(const Duration(milliseconds: 2400), () {
        if (mounted) {
          setState(() {
            _isSaved = false;
          });
        }
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("닉네임 변경에 실패했습니다. 네트워크 상태를 확인해 주세요."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build Method ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final trimmedInput = _nicknameController.text.trim();

    final String initial = trimmedInput.isNotEmpty
        ? trimmedInput[0]
        : (user.name.isNotEmpty ? user.name[0] : 'U');

    final bool hasChange = trimmedInput.isNotEmpty && trimmedInput != user.name;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildAvatarHero(user, initial),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildNicknameCard(),
                          const SizedBox(height: 10),
                          _buildUsernameCard(user),
                          const SizedBox(height: 14),
                          _buildSaveButton(user, hasChange),
                          const SizedBox(height: 12),
                          if (!hasChange && !_isSaved) _buildHintText(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI Components ──────────────────────────────────────────────────────────

  /// 1. 상단 헤더 (뒤로가기 + 타이틀)
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0x0D000000), width: 1),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: Color(0xFF172040),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "계정 설정",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.76,
              color: Color(0xFF172040),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. 아바타 히어로 영역
  Widget _buildAvatarHero(UserModel user, String initial) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x470284C7),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.36,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF2F7FC),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.54,
              color: Color(0xFF172040),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "@${user.username}",
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. 닉네임 입력 카드
  Widget _buildNicknameCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F172040),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              "닉네임 변경",
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.2,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _isFocused
                  ? const Color(0x080EA5E9)
                  : const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFFF1F5F9),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _nicknameController,
              focusNode: _focusNode,
              maxLength: 16,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172040),
              ),
              decoration: const InputDecoration(
                hintText: "새 닉네임 입력",
                hintStyle: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 15,
                ),
                counterText: "",
                border: InputBorder.none,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 12),
              child: Text(
                "${_nicknameController.text.length} / 16",
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. 사용자 ID 정보 카드 (수정 불가 표시)
  Widget _buildUsernameCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F172040),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "사용자 ID",
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "@${user.username}",
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "변경 불가",
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 5. 하단 저장 버튼
  Widget _buildSaveButton(UserModel user, bool hasChange) {
    final bool canTap = (hasChange || _isSaved) && !_isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: (!_isSaved && !hasChange && !_isLoading)
            ? const Color(0xFFE2E8F0)
            : null,
        borderRadius: BorderRadius.circular(18),
        gradient: _isSaved
            ? const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        )
            : ((hasChange || _isLoading)
            ? const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        )
            : null),
        boxShadow: _isSaved
            ? const [
          BoxShadow(
            color: Color(0x4710B981),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ]
            : ((hasChange || _isLoading)
            ? const [
          BoxShadow(
            color: Color(0x470284C7),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ]
            : []),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canTap ? () => _handleSave(user) : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "저장 중...",
                    style: GoogleFonts.anton(
                      fontSize: 15,
                      letterSpacing: 0.75,
                      color: Colors.white,
                    ),
                  ),
                ] else ...[
                  Icon(
                    _isSaved
                        ? Icons.check_circle_rounded
                        : Icons.person_rounded,
                    size: 18,
                    color: (_isSaved || hasChange)
                        ? Colors.white
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSaved ? "저장 완료!" : "저장하기",
                    style: GoogleFonts.anton(
                      fontSize: 15,
                      letterSpacing: 0.75,
                      color: (_isSaved || hasChange)
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 6. 안내 힌트 문구
  Widget _buildHintText() {
    return Text(
      "닉네임을 수정하면 저장 버튼이 활성화됩니다",
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        color: const Color(0xFFB0BDD0),
      ),
    );
  }
}