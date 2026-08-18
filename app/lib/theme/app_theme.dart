import 'package:flutter/material.dart';

class AppTheme {
  // 메인 컬러 팔레트 (Clean Apple Health Style)
  static const Color lightBackground = Color(0xFFF8FAFC); // 은은한 아이스 화이트 배경
  static const Color surfaceCard = Color(0xFFFFFFFF);     // 순백색 카드 배경
  static const Color primarySky = Color(0xFF00BFFE);      // 청량하고 밝은 하늘색 (#00BFFE)

  // 상태 컬러 팔레트
  static const Color accentGreen = Color(0xFF10B981);     // 올바른 자세/성공
  static const Color errorRed = Color(0xFFEF4444);        // 경고/오류
  static const Color errorOrange = Color(0xFFF59E0B);     // 주의

  static ThemeData get darkTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primarySky,
        surface: surfaceCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A), // 딥 슬레이트 텍스트
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2), // 연한 그리드 테두리
        ),
      ),
    );
  }
}