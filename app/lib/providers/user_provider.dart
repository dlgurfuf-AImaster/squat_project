import 'package:flutter/material.dart';
import '../models/user_model.dart'; // 기존에 만든 UserModel 경로

class UserProvider extends ChangeNotifier {
  // UserModel.dummy()로 초기화
  UserModel _user = UserModel.dummy();

  UserModel get user => _user;

  // 로그인 처리 또는 프로필 불러오기 시 활용
  void setUser(UserModel newUser) {
    _user = newUser;
    notifyListeners();
  }

  // 닉네임/이름 변경 메서드 예시
  void updateName(String newName) {
    _user = UserModel(
      id: _user.id,
      username: _user.username,
      name: newName,
    );
    notifyListeners();
  }
}