import 'package:flutter/material.dart';
import 'dart:async';
import 'loading_page.dart'; // For Quick Find
import 'sign_in.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  String _displayedText1 = "";
  String _displayedText2 = "";
  final String _fullText1 = "Welcome to Quick Job";
  final String _fullText2 = "Mobile App";
  int _textIndex1 = 0;
  int _textIndex2 = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    setState(() {
      _displayedText1 = "";
      _displayedText2 = "";
      _textIndex1 = 0;
      _textIndex2 = 0;
    });
    // Animate first line
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 110), (timer) {
      if (_textIndex1 < _fullText1.length) {
        setState(() {
          _displayedText1 += _fullText1[_textIndex1];
          _textIndex1++;
        });
      } else if (_textIndex2 < _fullText2.length) {
        setState(() {
          _displayedText2 += _fullText2[_textIndex2];
          _textIndex2++;
        });
      } else {
        timer.cancel();
        // Restart animation after a 2 second pause
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _startTypewriter();
        });
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
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
          // Content
          Column(
            children: [
              Expanded(
                flex: 9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Logo (increased size)
                    Image.asset(
                      'assets/logo.png',
                      height: 180,
                    ),
                    const SizedBox(height: 28),
                    // Typewriter Welcome Text (two lines)
                    Column(
                      children: [
                        Text(
                          _displayedText1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.black54,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _displayedText2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                blurRadius: 5,
                                color: Colors.black54,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),
                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInPage(),
                                ),
                              );
                              _startTypewriter();
                            },
                            child: const Text("Login"),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade200,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoadingPage(),
                                ),
                              );
                              _startTypewriter();
                            },
                            child: const Text("Quick Find"),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 18.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '© 2025 QuickJob. All rights reserved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Software Version 1.0.0',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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
