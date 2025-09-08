import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'sign_in.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _lastController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp(BuildContext context) async {
    final first = _firstController.text.trim();
    final last = _lastController.text.trim();

    if (first.isEmpty || last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill both First Name & Last Name fields')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  // Force the account chooser to appear by signing out any previously
  // authenticated GoogleSignIn instance before starting a new sign-in.
  await googleSignIn.signOut();
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // user cancelled
        setState(() => _loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('User is null after sign-in');

      // Check if user already registered in Firestore
      final docRef = FirebaseFirestore.instance.collection('userlog').doc(user.uid);
      final existing = await docRef.get();
      if (existing.exists) {
        // If already registered, sign out and show message
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This account already registered. Try another Account!')),
          );
          setState(() => _loading = false);
        }
        return;
      }

      // Write/update Firestore - collection: userlog 
      await docRef.set({
        'accountType': 'Employee',
        'createdAt': FieldValue.serverTimestamp(),
        'email': user.email ?? '',
        'firstName': first,
        'lastName': last,
        'uid': user.uid,
      }, SetOptions(merge: true));

      // Show success and navigate to a short loading screen that goes to SignInPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegisterSuccessPage(firstName: first)),
        );
      }
    } catch (error, stack) {
      // Show error
      debugPrint('Sign-up error: $error');
      debugPrint('$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
                        controller: _firstController,
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
                        controller: _lastController,
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
                          onPressed: _loading ? null : () => _handleSignUp(context),
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Sign Up with Gmail', style: TextStyle(fontSize: 16)),
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

class RegisterSuccessPage extends StatefulWidget {
  final String firstName;
  const RegisterSuccessPage({super.key, required this.firstName});

  @override
  State<RegisterSuccessPage> createState() => _RegisterSuccessPageState();
}

class _RegisterSuccessPageState extends State<RegisterSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _controller.forward();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
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
          Stack(
            children: [
              Center(
                child: SizedBox(
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
                      // Larger logo centered inside the rotating ring
                      ClipRRect(
                        borderRadius: BorderRadius.circular(56),
                        child: Image.asset('assets/logo.png', height: 120, width: 120, fit: BoxFit.cover),
                      ),
                    ],
                  ),
                ),
              ),
              // Place the success text slightly below center without moving the animation
              Align(
                alignment: const Alignment(0, 0.62),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: const Text(
                    'User Registration Successful!...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
