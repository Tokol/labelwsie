import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive.dart';
  // ⭐ IMPORTANT !!!
import 'package:provider/provider.dart';

import 'pref_wizard_screen.dart';
import 'profile_selection.dart';
import 'splash_screen.dart';
import 'dasboard/dashboard.dart';
import 'state/pref_store.dart';
import 'state/dashboard_controller.dart';
import 'onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⭐ REQUIRED FOR WEB (fixes blank screen on refresh)
  //await HiveFlutter.init();


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreferenceStore()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
      ],
      child: const LabelWiseDemoApp(),
    ),
  );
}

class LabelWiseDemoApp extends StatelessWidget {
  const LabelWiseDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Label Wise',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.greenAccent,
        colorScheme: const ColorScheme.dark(primary: Colors.greenAccent),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: "/splash",

      routes: {
        "/splash": (_) => const SplashScreen(),
        "/onboarding": (_) => const OnboardingScreen(),
        "/preferences": (_) => const ProfileSelectionScreen(),
        "/home": (_) => const DashboardScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == "/preferencesWizard") {
          final args = settings.arguments;

          // If refreshed → redirect safely
          if (args == null || args is! Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(context, "/preferences");
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          }

          // EXACT selected mapping
          final selected = {
            "religion": args["religion"] == true,
            "ethical": args["ethical"] == true,
            "allergy": args["allergy"] == true,
            "medical": args["medical"] == true,
            "fitness": args["fitness"] == true,
          };

          // EXACT initial data merge
          final Map<String, dynamic> initialData = {};

          if (args["initialData"] is Map) {
            initialData.addAll(Map<String, dynamic>.from(args["initialData"]));
          }
          if (args["initialReligion"] != null) {
            initialData["initialReligion"] = args["initialReligion"];
          }
          if (args["initialStrictness"] != null) {
            initialData["initialStrictness"] = args["initialStrictness"];
          }

          final fromProfile = args["fromProfile"] == true;

          return MaterialPageRoute(
            builder: (_) => PreferencesWizardScreen(
              selected: selected,
              initialData: initialData.isEmpty ? null : initialData,
              fromProfile: fromProfile,
            ),
          );
        }

        // fallback
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Unknown route")),
          ),
        );
      },
    );
  }
}
