import 'package:frub/models/user_model.dart';

enum EventStatus {
  draft,
  published,
  cancelled,
  completed
}

enum AttendanceStatus {
  attending,
  maybe,
  notAttending
}

class Event {
  final String id;
  final String title;
  final String description;
  final String organization;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String createdBy;
  final EventStatus status;
  final List<EventAttendee> attendees;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated fields
  Organization? organizationDetails;
  User? creatorDetails;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.organization,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.createdBy,
    this.status = EventStatus.draft,
    List<EventAttendee>? attendees,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.organizationDetails,
    this.creatorDetails,
  })  : attendees = attendees ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      organization: json['organization'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      location: json['location'],
      createdBy: json['createdBy'],
      status: _parseEventStatus(json['status']),
      attendees: (json['attendees'] as List?)
              ?.map((attendee) => EventAttendee.fromJson(attendee))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      organizationDetails: json['organization'] is Map<String, dynamic>
          ? Organization.fromJson(json['organization'])
          : null,
      creatorDetails: json['createdBy'] is Map<String, dynamic>
          ? User.fromJson(json['createdBy'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'organization': organization,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'status': status.toString().split('.').last,
    };
  }

  static EventStatus _parseEventStatus(String? status) {
    if (status == null) return EventStatus.draft;
    
    switch (status.toLowerCase()) {
      case 'draft':
        return EventStatus.draft;
      case 'published':
        return EventStatus.published;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'completed':
        return EventStatus.completed;
      default:
        return EventStatus.draft;
    }
  }
}

class EventAttendee {
  final String userId;
  final AttendanceStatus status;
  final DateTime registeredAt;
  User? user; // Populated user data

  EventAttendee({
    required this.userId,
    required this.status,
    DateTime? registeredAt,
    this.user,
  }) : registeredAt = registeredAt ?? DateTime.now();

  factory EventAttendee.fromJson(Map<String, dynamic> json) {
    return EventAttendee(
      userId: json['user'] ?? json['userId'],
      status: _parseAttendanceStatus(json['status']),
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'])
          : DateTime.now(),
      user: json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'status': status.toString().split('.').last,
    };
  }

  static AttendanceStatus _parseAttendanceStatus(String? status) {
    if (status == null) return AttendanceStatus.notAttending;
    
    switch (status.toLowerCase()) {
      case 'attending':
        return AttendanceStatus.attending;
      case 'maybe':
        return AttendanceStatus.maybe;
      case 'notattending':
        return AttendanceStatus.notAttending;
      default:
        return AttendanceStatus.notAttending;
    }
  }
} 