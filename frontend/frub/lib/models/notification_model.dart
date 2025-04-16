enum NotificationType {
  general,
  event,
  organization,
  comment
}

class Notification {
  final String id;
  final String recipient;
  final String title;
  final String message;
  final NotificationType type;
  final bool read;
  final RelatedEntity? relatedEntity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    required this.recipient,
    required this.title,
    required this.message,
    required this.type,
    this.read = false,
    this.relatedEntity,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'] ?? json['id'],
      recipient: json['recipient'],
      title: json['title'],
      message: json['message'],
      type: _parseNotificationType(json['type']),
      read: json['read'] ?? false,
      relatedEntity: json['relatedEntity'] != null
          ? RelatedEntity.fromJson(json['relatedEntity'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient': recipient,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'read': read,
      'relatedEntity': relatedEntity?.toJson(),
    };
  }

  static NotificationType _parseNotificationType(String? type) {
    if (type == null) return NotificationType.general;
    
    switch (type.toLowerCase()) {
      case 'general':
        return NotificationType.general;
      case 'event':
        return NotificationType.event;
      case 'organization':
        return NotificationType.organization;
      case 'comment':
        return NotificationType.comment;
      default:
        return NotificationType.general;
    }
  }
}

class RelatedEntity {
  final String entityType;
  final String entityId;

  RelatedEntity({
    required this.entityType,
    required this.entityId,
  });

  factory RelatedEntity.fromJson(Map<String, dynamic> json) {
    return RelatedEntity(
      entityType: json['entityType'],
      entityId: json['entityId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entityType': entityType,
      'entityId': entityId,
    };
  }
} 