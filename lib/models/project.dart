import 'dart:convert';
import '../utils/date_time_utils.dart';

class Project {
  final int id;
  final String title;
  final String type;
  final String field;
  final String stage;
  final String? blocker;
  final String? helpType;
  final List<String> images;
  final bool isPublicProgress;
  final String status;
  final int ownerId;
  final String ownerNickname;
  final String ownerEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Progress> progress;
  final int? progressCount;
  final int? intentsCount;

  Project({
    required this.id,
    required this.title,
    required this.type,
    required this.field,
    required this.stage,
    this.blocker,
    this.helpType,
    this.images = const [],
    required this.isPublicProgress,
    required this.status,
    required this.ownerId,
    required this.ownerNickname,
    required this.ownerEmail,
    required this.createdAt,
    required this.updatedAt,
    this.progress = const [],
    this.progressCount,
    this.intentsCount,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      field: json['field'],
      stage: json['stage'],
      blocker: json['blocker'],
      helpType: json['help_type'],
      images: _parseImages(json['images']),
      isPublicProgress: json['is_public_progress'] == 1,
      status: json['status'],
      ownerId: json['owner_id'],
      ownerNickname: json['owner_nickname'] ?? '',
      ownerEmail: json['owner_email'] ?? '',
      createdAt: parseServerDateTime(json['created_at']),
      updatedAt: parseServerDateTime(json['updated_at']),
      progress: (json['progress'] as List<dynamic>?)
          ?.map((p) => Progress.fromJson(p))
          .toList() ?? [],
      progressCount: json['progress_count'],
      intentsCount: json['intents_count'],
    );
  }

  static List<String> _parseImages(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }
}

class Progress {
  final int id;
  final int projectId;
  final String content;
  final String? summary;
  final DateTime createdAt;

  Progress({
    required this.id,
    required this.projectId,
    required this.content,
    this.summary,
    required this.createdAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['id'],
      projectId: json['project_id'],
      content: json['content'],
      summary: json['summary'],
      createdAt: parseServerDateTime(json['created_at']),
    );
  }
}
