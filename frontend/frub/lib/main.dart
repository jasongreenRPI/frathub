import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/ride_service.dart';
import 'services/user_service.dart';

void main() {
  // Initialize services
  final rideService = RideService();
  rideService.initWithDummyData();
  
  // Initialize user service (if needed)
  final userService = UserService();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
     
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LXA Ride Share',
      theme: ThemeData(
        primaryColor: const Color(0xFF4B0082),
        scaffoldBackgroundColor: const Color(0xFF4B0082),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B0082),
          primary: const Color(0xFF4B0082),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4B0082),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF4B0082),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}