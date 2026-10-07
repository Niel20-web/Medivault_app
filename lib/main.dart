import 'package:flutter/material.dart';

import 'screens/homescreen.dart';
import 'screens/welcome_screen.dart';
import 'services/session_manager.dart';
import 'utils/appcolors.dart';

void main() {
  runApp(const MedivaultApp());
}

class MedivaultApp extends StatelessWidget {
  const MedivaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SessionManager.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MediVault',
      home: const SessionGate(),
    );
  }
}

/// Decides the first screen: users with a valid saved session go straight
/// to the home screen, everyone else sees the welcome/login flow.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = SessionManager.instance.hasValidSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Appcolors.background,
            body: Center(
              child: CircularProgressIndicator(color: Appcolors.primary),
            ),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}
