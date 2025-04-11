import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'ride_screen.dart';
import 'user_profile_screen.dart';
import 'login_screen.dart';
import 'events_screen.dart';
import '/screens/admin/ride_admin_screens.dart';

// The HomeScreen widget is the main screen of the app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// The _HomeScreenState class manages the state of the HomeScreen widget.
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final userService = UserService();
  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    
    // For demo purposes, every user is an admin
    // In the real app, we would check the user's role
    setState(() {
      _isAdmin = true;
    });
  }
  
  // This method is called when the user taps on a tab in the bottom navigation bar.
  @override
  Widget build(BuildContext context) {
    // Create the different tab pages
    final List<Widget> _pages = [
      const Center(
        child: Text(
          'Welcome User!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      const RideScreen(),
      const EventsScreen(isAdmin: true), 
      const UserProfileScreen(),
    ];
  
  // Add admin page if user is admin
  if (_isAdmin) {
    _pages.add(const RideAdminScreen());
  }
      
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 78, 14, 89),
      appBar: AppBar(
        title: const Text('FRUB'),
        backgroundColor: Colors.purple[800],
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RideAdminScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Log out and return to login screen
              userService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // If the admin tab is tapped and it exists
          if (_isAdmin && index == _pages.length - 1) {
            setState(() {
              _selectedIndex = index;
            });
          }
          // For other tabs
          else if (index < (_isAdmin ? _pages.length - 1 : _pages.length)) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        // This ensures labels are always visible
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Ride',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.event), 
            label: 'Events',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          if (_isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
        selectedItemColor: Colors.purple[800],
        unselectedItemColor: Colors.grey[600],
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton(
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.admin_panel_settings),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RideAdminScreen()),
          );
        },
      ) : null,
    );
  }
}