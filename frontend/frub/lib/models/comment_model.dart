import 'package:frub/models/user_model.dart';

class Comment {
  final String id;
  final String content;
  final String author;
  final String event;
  final String? parentComment;
  final List<String> likes;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated fields
  User? authorDetails;
  List<Comment> replies = [];

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.event,
    this.parentComment,
    List<String>? likes,
    this.isEdited = false,
    this.editedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.authorDetails,
    List<Comment>? replies,
  })  : likes = likes ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        replies = replies ?? [];

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'] ?? json['id'],
      content: json['content'],
      author: json['author'],
      event: json['event'],
      parentComment: json['parentComment'],
      likes: (json['likes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      authorDetails: json['author'] is Map<String, dynamic>
          ? User.fromJson(json['author'])
          : null,
      replies: (json['replies'] as List?)
              ?.map((reply) => Comment.fromJson(reply))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'event': event,
      'parentComment': parentComment,
    };
  }
} 