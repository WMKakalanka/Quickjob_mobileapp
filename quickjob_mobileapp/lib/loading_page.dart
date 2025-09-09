
// loading_page.dart
// - Intermediate page used for Quick Find lookup.
// - Provides a small loading animation and then navigates to the QuickFindPage.
// - Keep logic here lightweight; heavy work should be moved to providers/services.
import 'package:flutter/material.dart';
import 'quick_find_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    // Rotation controller for the circular indicator
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const QuickFindPage()),
      );
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),

          // Center content
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating circular progress around logo
                SizedBox(
                  height: 140,
                  width: 140,
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 6.3, // ~2*PI
                        child: child,
                      );
                    },
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      color: Colors.purple.withOpacity(0.7),
                    ),
                  ),
                ),

                // Logo at center
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                ),
              ],
            ),
          ),

          // Loading text at bottom
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: const Text(
              'Loading to Quick Find...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 5,
                    color: Colors.black54,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
