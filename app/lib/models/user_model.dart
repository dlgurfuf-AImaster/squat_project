class UserModel {
  final int id;
  final String username;
  final String name;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
  });

  /// 백엔드 API 응답(JSON) -> UserModel 변환 (Null/타입 에러 방지)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.parse(json['id'].toString()), // String으로 넘어와도 int로 변환
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
    );
  }

  /// UserModel -> JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
    };
  }

  /// 프론트엔드 UI 개발용 더미 데이터
  factory UserModel.dummy() {
    return UserModel(
      id: 100,
      username: 'test123',
      name: '테스트',
    );
  }
}