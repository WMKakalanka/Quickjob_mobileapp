import 'landing_page.dart';
import 'sign_up.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  Future<void> _handleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      await googleSignIn.signIn();
      // TODO: Handle successful sign-in
    } catch (error) {
      // TODO: Handle error
    }
  }

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
                        'Login',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.purpleAccent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _handleSignIn,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/google_logo.png', // Use official Google logo
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text('Sign In with Google', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Are you a new user?', style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            child: const Text('Sign Up', style: TextStyle(color: Colors.purpleAccent)),
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
