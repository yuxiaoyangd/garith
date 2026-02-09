class User {
  final int id;
  final String email;
  final String nickname;
  final List<String> skills;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.skills,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'skills': skills,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
