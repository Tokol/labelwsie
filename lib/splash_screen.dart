import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'services/installation_registration_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    final box = await Hive.openBox("app_data");
    await _ensureInstallationId(box);
    await _ensureInstallationRegistration(box);

    final hasSeenOnboarding = box.get("hasSeenOnboarding", defaultValue: false);
    final hasSetPreferences = box.get("hasSetPreferences", defaultValue: false);

    print("hasSeenOnboarding: $hasSeenOnboarding");
    print("hasSetPreferences: $hasSetPreferences");


    await Future.delayed(const Duration(milliseconds: 800)); // small splash delay

    if (!hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, "/onboarding");
      return;
    }

    if (!hasSetPreferences) {
      Navigator.pushReplacementNamed(context, "/preferences");
      return;
    }

    Navigator.pushReplacementNamed(context, "/home");
  }

  Future<void> _ensureInstallationId(Box box) async {
    final existingId = box.get("installation_id")?.toString().trim();
    if (existingId != null && existingId.isNotEmpty) {
      return;
    }

    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final suffix = random.nextInt(0x7fffffff).toRadixString(16);
    final installationId = "lw_${timestamp}_$suffix";

    await box.put("installation_id", installationId);
  }

  Future<void> _ensureInstallationRegistration(Box box) async {
    try {
      await InstallationRegistrationService.ensureRegistered(box);
    } catch (error, stackTrace) {
      debugPrint("Installation registration failed: $error");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FCF7),
              Color(0xFFF1F7F2),
              Color(0xFFEAF3EC),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -80,
              left: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8DE0A8).withOpacity(0.16),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -30,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2F7A4B).withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  children: [
                    const Spacer(),
                    ScaleTransition(
                      scale: _pulse,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 132,
                            height: 132,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 118,
                                  height: 118,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF8DE0A8)
                                            .withOpacity(0.22),
                                        const Color(0xFF8DE0A8)
                                            .withOpacity(0.03),
                                      ],
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  "assets/icons/logo_transparent.png",
                                  width: 86,
                                  height: 86,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            "Label Wise",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: Color(0xFF1E5A39),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "AI-powered food label analysis",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Color(0xFF6A7C6F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.74),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFD7E5DA),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Color(0xFF2F7A4B),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Preparing your experience",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF31523F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "Created by Suresh Lama at Novia UAS",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF7A8D80),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
