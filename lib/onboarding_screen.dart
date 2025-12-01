import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:hive_ce/hive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<_OnboardPage> pages = [
    _OnboardPage(
      title: "Your Privacy Comes First",
      subtitle:
      "LabelWise keeps your dietary preferences only on your device.\nWe never upload or share your religion, allergies, or personal profile.",
      imageName: "assets/lottie/square_box.json",
    ),
    _OnboardPage(
      title: "Scan, Understand, Eat Confidently",
      subtitle:
      "LabelWise reads ingredients for you, explains them clearly,\nand helps you enjoy food that aligns with your dietary choices.",
      imageName: "assets/lottie/ocr.json",
    ),
    _OnboardPage(
      title: "Personalize Your Experience",
      subtitle:
      "Set your dietary choices to get accurate and helpful guidance when you scan food labels.",
      imageName: "assets/lottie/select.json",
    ),
  ];

  void _finishOnboarding() async {
    final box = await Hive.openBox("app_data");
    await box.put("hasSeenOnboarding", true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/preferences");
  }


  @override
  Widget build(BuildContext context) {
    // Detect screen height category
    final double height = MediaQuery.of(context).size.height;
    final bool isSmallScreen = height < 600;        // iPhone SE, 8, old devices
    final bool isMediumScreen = height < 750;       // iPhone 12/13/14 mini, etc.

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: _currentIndex < pages.length - 1
                  ? TextButton(
                onPressed: () => _finishOnboarding(),
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: const Color(0xFF00C853),
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              )
                  : SizedBox(height: isSmallScreen ? 16 : 24),
            ),

            // Main Content - Fully Dynamic
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (_, index) {
                  final page = pages[index];

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 32,
                    ),
                    child: Column(
                      children: [
                        // Dynamic top spacing
                        SizedBox(height: isSmallScreen ? 10 : 20),

                        // Lottie Animation - Responsive height
                        Expanded(
                          flex: isSmallScreen ? 4 : 5, // Takes more space on small screens
                          child: Lottie.asset(
                            page.imageName,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 20 : 30),

                        // Title - Responsive font
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF004D40),
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Subtitle - Responsive font
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: isSmallScreen ? 15 : 17,
                            height: 1.5,
                          ),
                        ),

                        // Bottom flexible space
                        SizedBox(height: isSmallScreen ? 20 : 40),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 10,
                  width: _currentIndex == i ? (isSmallScreen ? 28 : 32) : 10,
                  decoration: BoxDecoration(
                    color: _currentIndex == i
                        ? const Color(0xFF00C853)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Button - Full width & responsive
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 24 : 40,
                vertical: 10,
              ),
              child: SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 50 : 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentIndex == pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentIndex == pages.length - 1 ? "Get Started" : "Next",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 17 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 10), // Safe bottom
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String title;
  final String subtitle;
  final String imageName;
  _OnboardPage({required this.title, required this.subtitle, required this.imageName});
}