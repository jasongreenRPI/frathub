import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frub/models/user_model.dart';
import 'package:frub/models/organization_model.dart';
import 'package:frub/models/event_model.dart';
import 'package:frub/models/comment_model.dart';
import 'package:frub/models/notification_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Base URL for the API
  final String baseUrl = 'http://localhost:3000/api';
  
  // Authentication token
  String? _authToken;
  
  // Setter for auth token
  set authToken(String? token) {
    _authToken = token;
  }
  
  // Getter for auth token
  String? get authToken => _authToken;
  
  // Headers for API requests
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Authentication methods
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _authToken = data['token'];
      return User.fromJson(data['user']);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<User> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _authToken = data['token'];
      return User.fromJson(data['user']);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  // User methods
  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['data']);
    } else {
      throw Exception('Failed to get current user: ${response.body}');
    }
  }

  Future<User> updateUserProfile(Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['data']);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // Organization methods
  Future<List<Organization>> getOrganizations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/organizations'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((org) => Organization.fromJson(org))
          .toList();
    } else {
      throw Exception('Failed to get organizations: ${response.body}');
    }
  }

  Future<Organization> getOrganization(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/organizations/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Organization.fromJson(data['data']);
    } else {
      throw Exception('Failed to get organization: ${response.body}');
    }
  }

  Future<Organization> createOrganization(Map<String, dynamic> orgData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/organizations'),
      headers: _headers,
      body: jsonEncode(orgData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Organization.fromJson(data['data']);
    } else {
      throw Exception('Failed to create organization: ${response.body}');
    }
  }

  Future<Organization> updateOrganization(String id, Map<String, dynamic> orgData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/organizations/$id'),
      headers: _headers,
      body: jsonEncode(orgData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Organization.fromJson(data['data']);
    } else {
      throw Exception('Failed to update organization: ${response.body}');
    }
  }

  Future<void> deleteOrganization(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/organizations/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete organization: ${response.body}');
    }
  }

  // Event methods
  Future<List<Event>> getEvents({String? organizationId, String? status}) async {
    String url = '$baseUrl/events';
    if (organizationId != null) {
      url += '?organization=$organizationId';
    }
    if (status != null) {
      url += url.contains('?') ? '&status=$status' : '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((event) => Event.fromJson(event))
          .toList();
    } else {
      throw Exception('Failed to get events: ${response.body}');
    }
  }

  Future<Event> getEvent(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Event.fromJson(data['data']);
    } else {
      throw Exception('Failed to get event: ${response.body}');
    }
  }

  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: _headers,
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Event.fromJson(data['data']);
    } else {
      throw Exception('Failed to create event: ${response.body}');
    }
  }

  Future<Event> updateEvent(String id, Map<String, dynamic> eventData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/events/$id'),
      headers: _headers,
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Event.fromJson(data['data']);
    } else {
      throw Exception('Failed to update event: ${response.body}');
    }
  }

  Future<void> deleteEvent(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete event: ${response.body}');
    }
  }

  Future<void> registerForEvent(String eventId, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/$eventId/register'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register for event: ${response.body}');
    }
  }

  Future<void> updateAttendanceStatus(String eventId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/events/$eventId/attendance'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update attendance status: ${response.body}');
    }
  }

  // Comment methods
  Future<List<Comment>> getCommentsForEvent(String eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/comments/event/$eventId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((comment) => Comment.fromJson(comment))
          .toList();
    } else {
      throw Exception('Failed to get comments: ${response.body}');
    }
  }

  Future<List<Comment>> getRepliesForComment(String commentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/comments/$commentId/replies'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((comment) => Comment.fromJson(comment))
          .toList();
    } else {
      throw Exception('Failed to get replies: ${response.body}');
    }
  }

  Future<int> getCommentCountForEvent(String eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/comments/event/$eventId/count'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'];
    } else {
      throw Exception('Failed to get comment count: ${response.body}');
    }
  }

  Future<Comment> createComment(Map<String, dynamic> commentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/comments'),
      headers: _headers,
      body: jsonEncode(commentData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Comment.fromJson(data['data']);
    } else {
      throw Exception('Failed to create comment: ${response.body}');
    }
  }

  Future<Comment> updateComment(String id, String content) async {
    final response = await http.put(
      Uri.parse('$baseUrl/comments/$id'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Comment.fromJson(data['data']);
    } else {
      throw Exception('Failed to update comment: ${response.body}');
    }
  }

  Future<void> deleteComment(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/comments/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete comment: ${response.body}');
    }
  }

  Future<Comment> likeComment(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/comments/$id/like'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Comment.fromJson(data['data']);
    } else {
      throw Exception('Failed to like comment: ${response.body}');
    }
  }

  Future<Comment> unlikeComment(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/comments/$id/like'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Comment.fromJson(data['data']);
    } else {
      throw Exception('Failed to unlike comment: ${response.body}');
    }
  }

  // Notification methods
  Future<List<Notification>> getNotifications({bool? read, String? type}) async {
    String url = '$baseUrl/notifications';
    if (read != null) {
      url += '?read=$read';
    }
    if (type != null) {
      url += url.contains('?') ? '&type=$type' : '?type=$type';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((notification) => Notification.fromJson(notification))
          .toList();
    } else {
      throw Exception('Failed to get notifications: ${response.body}');
    }
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'];
    } else {
      throw Exception('Failed to get unread notification count: ${response.body}');
    }
  }

  Future<Notification> getNotification(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Notification.fromJson(data['data']);
    } else {
      throw Exception('Failed to get notification: ${response.body}');
    }
  }

  Future<Notification> markNotificationAsRead(String id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Notification.fromJson(data['data']);
    } else {
      throw Exception('Failed to mark notification as read: ${response.body}');
    }
  }

  Future<Notification> markNotificationAsUnread(String id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$id/unread'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Notification.fromJson(data['data']);
    } else {
      throw Exception('Failed to mark notification as unread: ${response.body}');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/mark-all-read'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read: ${response.body}');
    }
  }

  Future<void> deleteNotification(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/notifications/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete notification: ${response.body}');
    }
  }
} 