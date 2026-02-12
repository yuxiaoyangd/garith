import '../utils/date_time_utils.dart';

class Intent {
  final int id;
  final int projectId;
  final int userId;
  final String offer;
  final String expect;
  final String contact;
  final String status;
  final DateTime createdAt;
  final String? projectTitle;
  final String? projectField;
  final String? projectStage;
  final String? userNickname;
  final String? userEmail;
  final String? projectOwnerNickname;
  final int? projectOwnerId;

  Intent({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.offer,
    required this.expect,
    required this.contact,
    required this.status,
    required this.createdAt,
    this.projectTitle,
    this.projectField,
    this.projectStage,
    this.userNickname,
    this.userEmail,
    this.projectOwnerNickname,
    this.projectOwnerId,
  });

  factory Intent.fromJson(Map<String, dynamic> json) {
    return Intent(
      id: json['id'],
      projectId: json['project_id'],
      userId: json['user_id'],
      offer: json['offer'],
      expect: json['expect'],
      contact: json['contact'],
      status: json['status'],
      createdAt: parseServerDateTime(json['created_at']),
      projectTitle: json['project_title'],
      projectField: json['project_field'],
      projectStage: json['project_stage'],
      userNickname: json['nickname'] ?? json['user_nickname'],
      userEmail: json['email'] ?? json['user_email'],
      projectOwnerNickname: json['project_owner_nickname'],
      projectOwnerId: json['project_owner_id'],
    );
  }
}
