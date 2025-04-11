// This file manages user data across the app

// Class to represent a user
class User {
  final String email;
  final String password;
  String name;
  String dob;
  String affiliation;
  String position;

  User({
    required this.email,
    required this.password,
    this.name = '',
    this.dob = '',
    this.affiliation = '',
    this.position = '',
  });
}

// UserService class to manage user-related operations
class UserService {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Currently logged in user
  User? _currentUser;

  // Database of users
  final List<User> _users = [
    User(
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User',
      dob: '01/01/1990',
      affiliation: 'Affiliated with LXA',
      position: 'Member',
    ),
    User(
      email: 'user@frub.com',
      password: 'frubuser',
      name: 'Frub User',
      dob: '05/15/1995',
      affiliation: 'Affiliated with LXA',
      position: 'Treasurer',
    ),
    User(
      email: 'u1',
      password: 'u1',
      name: 'Demo User',
      dob: '07/02/1999',
      affiliation: 'Affiliated with LXA',
      position: 'Secretary',
    ),
  ];

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Get all emails (for checking existing emails)
  List<String> get allEmails => _users.map((user) => user.email).toList();

  // Login method
  bool login(String email, String password) {
    final user = _users.firstWhere(
      (user) => user.email == email && user.password == password,
      orElse: () => User(email: '', password: ''),
    );

    if (user.email.isNotEmpty) {
      _currentUser = user;
      return true;
    }
    return false;
  }

  // Register method
  void register(String email, String password) {
    final newUser = User(
      email: email,
      password: password,
      name: 'New User', // Default values
      dob: '',
      affiliation: 'Affiliated with LXA',
      position: 'Member',
    );
    
    _users.add(newUser);
    _currentUser = newUser; // Automatically log in the new user
  }

  // Logout method
  void logout() {
    _currentUser = null;
  }

  // Update profile
  void updateProfile({
    String? name,
    String? dob,
    String? affiliation,
    String? position,
  }) {
    if (_currentUser != null) {
      if (name != null) _currentUser!.name = name;
      if (dob != null) _currentUser!.dob = dob;
      if (affiliation != null) _currentUser!.affiliation = affiliation;
      if (position != null) _currentUser!.position = position;
    }
  }

  // Check if email is already registered
  bool isEmailRegistered(String email) {
    return _users.any((user) => user.email == email);
  }
}