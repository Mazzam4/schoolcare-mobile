import 'dart:ui';
import 'package:flutter/material.dart';
import '/features/report/create_report_modal.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // White glass
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.black.withOpacity(0.08), // Dark border
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(Icons.house_rounded, 'Beranda', 0),
                _buildNavItem(Icons.description_rounded, 'Laporan', 1),
                _buildCenterButton(context), // Pass context
                _buildNavItem(Icons.history_rounded, 'Riwayat', 3),
                _buildNavItem(Icons.person_rounded, 'Profil', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Center Plus Button - Dark Accent dengan Bottom Sheet
  Widget _buildCenterButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Memunculkan Bottom Sheet Laporan yang bisa ditarik
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // WAJIB TRUE agar bisa full screen
          backgroundColor: Colors
              .transparent, // Background transparan agar border radius modal terlihat
          builder: (context) => const CreateReportModal(),
        );

        // Tetap panggil onTap jika diperlukan
        onTap(2);
      },
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  // Nav Item with Icon - Dark on White
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withOpacity(
                          0.08,
                        ) // Dark background untuk selected
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? const Color(0xFF1C1C1E) // Dark saat selected
                      : Colors.black.withOpacity(
                          0.4,
                        ), // Light gray saat tidak selected
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1C1C1E)
                      : Colors.black.withOpacity(0.4),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
