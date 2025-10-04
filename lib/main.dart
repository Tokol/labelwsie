import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math; // For scan line animation
import 'dart:ui' as ui; // For Matrix4 transform

import 'camera_scan_page.dart';

void main() {
  runApp(LabelWiseDemoApp());
}

class LabelWiseDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Label-wise Prototype 1',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.greenAccent,
        colorScheme: const ColorScheme.dark(primary: Colors.greenAccent),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFF0A0E21), // Dark professional background
      ),
      home: const LandingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LandingScreen extends StatefulWidget { // Make Stateful for animations
  const LandingScreen({Key? key}) : super(key: key);

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scanController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    // Fade-in animation for content
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Scan line animation (loops)
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double buttonSize = 80;

    return Scaffold(
      body: SafeArea( // Add SafeArea for notches
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF0A0E21), const Color(0xFF1C1F38)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Subtle Scan-Line Animation (thematic overlay)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: ScanLinePainter(_scanAnimation.value),
                );
              },
            ),
            // Vignette Overlay (darkens edges for focus)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, -0.5),
                    radius: 1.5,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Center Content with Fade-In
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo / Lottie Animation
                    Lottie.asset(
                      'assets/lottie/gKpzCgcPT5.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      onLoaded: (composition) {
                        if (composition != null) {
                          _scanController.duration = composition.duration;
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Title with Glow Effect
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        "Label-wise Prototype 1",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Subtitle with Improved Readability
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        "Demo prototype to scan food package ingredients, translate them, and summarize their usage and dietary recommendations.\nCurrently, with just a few functionalities for demonstration.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.4, // Better line spacing
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Footer Tagline
                    Text(
                      "v1.0 - Scan Smart, Eat Wise",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white54,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Middle Scan Button with Scale Animation
            Positioned(
              bottom: 40,
              left: MediaQuery.of(context).size.width / 2 - buttonSize / 2,
              child: GestureDetector(
                onTapDown: (_) {
                  // Scale down on press (use setState for simple toggle)
                  setState(() {}); // Trigger rebuild for animation
                },
                onTapUp: (_) {
                  setState(() {}); // Scale back
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CameraScanPage()),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.greenAccent, Colors.lightGreenAccent],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Transform.scale(
                    scale: 1.0, // Animate scaleY or use a state var like _buttonScale (0.95 on down)
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 40,
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

// Custom Painter for Scan Line Animation
class ScanLinePainter extends CustomPainter {
  final double progress;

  ScanLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final y = size.height * progress;
    path.moveTo(0, y);
    path.lineTo(size.width, y);

    // Add subtle wave for interest
    final wavePaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    final wavePath = Path();
    wavePath.moveTo(0, y - 5);
    wavePath.quadraticBezierTo(size.width / 2, y - 15, size.width, y - 5);
    wavePath.lineTo(size.width, y + 5);
    wavePath.lineTo(0, y + 5);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}