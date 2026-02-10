class User {
  final int id;
  final String email;
  final String nickname;
  final List<String> skills;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? bio;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.skills,
    required this.createdAt,
    this.avatarUrl,
    this.bio,
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
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'skills': skills,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }
}
