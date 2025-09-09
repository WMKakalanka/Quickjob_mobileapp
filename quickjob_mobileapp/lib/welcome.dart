// welcome.dart
// - A lightweight animated welcome screen shown after sign-in.
// - Provides a short visual transition before routing to the Employee dashboard or settings.
// - Keep animation lightweight to avoid blocking the first frame; navigation should occur after the animation completes.
import 'package:flutter/material.dart';
import 'employee.dart';

class WelcomePage extends StatefulWidget {
  final String firstName;
  const WelcomePage({super.key, required this.firstName});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _controller.repeat();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmployeePage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.png', fit: BoxFit.cover),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 190,
                  width: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _controller,
                        child: SizedBox(
                          height: 190,
                          width: 190,
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            color: Colors.purple.withOpacity(0.85),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(56),
                        child: Image.asset('assets/logo.png', height: 120, width: 120, fit: BoxFit.cover),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Login Successful...',
                  style: const TextStyle(color: Colors.white, fontSize: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.firstName,
                  style: const TextStyle(color: Colors.white70, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome Back!',
                  style: const TextStyle(color: Colors.white, fontSize: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
