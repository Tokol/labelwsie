import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive.dart';
import 'package:label_wise/pref_wizard_screen.dart';
import 'package:label_wise/profile_selection.dart';
import 'package:label_wise/splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math; // For scan line animation
import 'dart:ui' as ui; // For Matrix4 transform

import 'barcode_scan_screen.dart';
import 'camera_scan_page.dart';
import 'dasboard/dashboard.dart';
import 'dasboard/landing.dart';
import 'diet_pref/allergy_screen.dart';
import 'diet_pref/ethical_choice_screen.dart';
import 'diet_pref/lifestyle_goals_screen.dart';
import 'diet_pref/medical_choice_screen.dart';
import 'diet_pref/religion.dart';
import 'onboarding_screen.dart';

void main() {
  runApp(LabelWiseDemoApp());
}

class LabelWiseDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalKey<NavigatorState>(),
      title: 'Label Wise',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.greenAccent,
        colorScheme: const ColorScheme.dark(primary: Colors.greenAccent),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFF0A0E21), // Dark professional background
      ),
     // home:  ProfileSelectionScreen(),
     // home:ReligionCultureSelectionScreen(),
     // home: EthicalChoicesScreen(),
     // home: AllergiesScreen(),
     // home:MedicalNeedsScreen(),
    //  home:LifestyleGoalsScreen(),
    //   home:BarcodeScannerPage(
    //
    //   ),
      routes: {
        "/splash": (_) => const DashboardScreen(),
        "/onboarding": (_) => const OnboardingScreen(),
        "/preferences": (_) => const ProfileSelectionScreen(),
        "/home": (_) => const DashboardScreen(),

        "/preferencesWizard": (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          // SAFETY CHECK — Prevent crash
          if (args == null || args is! Map<String, bool>) {
            return const Scaffold(
              body: Center(
                child: Text("Invalid navigation: no preferences were selected."),
              ),
            );
          }

          return PreferencesWizardScreen(selected: args);
        },

      },
      initialRoute: "/splash",
      debugShowCheckedModeBanner: false,
    );
  }
}

