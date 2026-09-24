import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import '/core/widgets/custom_navbar.dart';
import '../report/report_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ReportScreen(),
    const SizedBox(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FE),
      extendBody: true, // PENTING! Biar body extend ke bawah navbar
      
      body: Stack(
        children: [
          // Main Content - extend sampai bottom
          Positioned.fill(
            child: _pages[_currentIndex],
          ),
          
          // Navbar di atas content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavbar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index != 2) {
                  setState(() {
                    _currentIndex = index;
                  });
                } 
              },
            ),
          ),
        ],
      ),
    );
  }
}