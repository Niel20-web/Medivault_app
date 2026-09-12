import 'package:flutter/material.dart';
import '../utils/appcolors.dart';
import 'login_screen.dart';
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _iconAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );

    // ICON
    _iconAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3),
      ),
    );

    // TITLE
    _titleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.65),
      ),
    );

    // TAGLINE
    _taglineAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0),
      ),
    );

    // BUTTON
    _buttonAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ICON
            FadeTransition(
              opacity: _iconAnimation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.75,
                  end: 1.0,
                ).animate(_iconAnimation),
                child: Image.asset(
                  'assets/images/medivault_logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TITLE
            AnimatedBuilder(
              animation: _titleAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _titleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: const Text(
                'MediVault',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Appcolors.primary,
                  letterSpacing: 2.0,
                  fontFamily: 'Roboto',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // TAGLINE
            AnimatedBuilder(
              animation: _taglineAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _taglineAnimation.value,
                    child: child,
                  ),
                );
              },
              child: const Text(
                'Your health. Your records.\nYour control.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Appcolors.secondaryText,
                  letterSpacing: 1.0,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // GET STARTED BUTTON
            FadeTransition(
              opacity: _buttonAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_buttonAnimation),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const login_screen(),
                      ), 
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                       Appcolors.primary, // Use the primary color from Appcolors
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}