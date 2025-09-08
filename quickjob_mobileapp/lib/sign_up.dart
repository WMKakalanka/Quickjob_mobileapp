import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'sign_in.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Custom background
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo above card
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                ),
                const SizedBox(height: 24),
                Container(
                  width: 400,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create an Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'First Name',
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintStyle: const TextStyle(color: Colors.white54),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Last Name',
                          filled: true,
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintStyle: const TextStyle(color: Colors.white54),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            // TODO: Implement sign up logic with Gmail
                          },
                          child: const Text('Sign Up with Gmail', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an Account?', style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInPage(),
                                ),
                              );
                            },
                            child: const Text('Login', style: TextStyle(color: Colors.purpleAccent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.purpleAccent, width: 2),
                            foregroundColor: Colors.purpleAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LandingPage(),
                              ),
                            );
                          },
                          child: const Text('Menu', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
