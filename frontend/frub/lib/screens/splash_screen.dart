import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';


/// SplashScreen widget that displays a loading screen with a logo and a message.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


/// State class for SplashScreen that handles the timer and navigation.
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Login Screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    });
  }


  /// Dispose method to cancel the timer if needed
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 78, 14, 89),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const Text(
              'FRUB',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
            const Text(
              'Fraternally Improving Connections',
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 233, 230, 230)
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 233, 230, 230)
              ),
            )
          ],
        ),
      ),
    );
  }
}