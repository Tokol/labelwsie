import 'package:flutter/material.dart';
import 'package:label_wise/dasboard/profile.dart';
import 'package:label_wise/dasboard/scan.dart';
import 'package:label_wise/dasboard/testscan.dart';
import 'package:lottie/lottie.dart';
import 'package:not_static_icons/not_static_icons.dart';

import 'home.dart';  // IMPORTANT import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    //ScanPage(),
    TestScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4CAF50),   // green
        unselectedItemColor: Colors.grey.shade500,
        showSelectedLabels: true,
        showUnselectedLabels: true,

        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_rounded, color: Color(0xFF4CAF50)),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Container(
              height: 52,
              width: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent, // inactive: no background
              ),
              child: Lottie.asset(
                "assets/lottie/barcode_scanner.json",
                animate: true,   // must be true so first frame is visible
                repeat: true,   // inactive: no loop
              ),
            ),

            activeIcon: Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withOpacity(0.15), // ✅ green background
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.25),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Lottie.asset(
                "assets/lottie/barcode_scanner.json",
                animate: true,   // active: animate
                repeat: true,
              ),
            ),

            label: "Scan",
          ),



          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person_rounded, color: Color(0xFF4CAF50)),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
