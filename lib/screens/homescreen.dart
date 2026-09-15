import 'package:flutter/material.dart';
import '../utils/appcolors.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final String username = 'Nathan';

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good Morning 👋';
    } else if (hour < 17) {
      return 'Good Afternoon 👋';
    } else {
      return 'Good Evening 👋';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // MediVault header
                  Text(
                    'MediVault',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Greeting
                  Text(
                    '${getGreeting()} $username',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.primaryText,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Your medical records, all in one place',
                    style: TextStyle(
                      fontSize: 15,
                      color: Appcolors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}