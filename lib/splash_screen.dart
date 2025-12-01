import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {

    final box = await Hive.openBox("app_data");

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: const Center(
        child: CircularProgressIndicator(
          color: Colors.greenAccent,
        ),
      ),
    );
  }
}
