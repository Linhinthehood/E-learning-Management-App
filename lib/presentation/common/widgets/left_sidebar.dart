import 'package:flutter/material.dart';
import '../styles/colors.dart';

class LeftSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const LeftSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                'F.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          // Navigation items
          _buildNavItem(Icons.home_rounded, 0, 'Dashboard'),
          const SizedBox(height: 30),
          _buildNavItem(Icons.calendar_today_rounded, 1, 'Semesters'),
          const SizedBox(height: 30),
          _buildNavItem(Icons.school_rounded, 2, 'Courses'),
          const SizedBox(height: 30),
          _buildNavItem(Icons.person_rounded, 3, 'Students'),
          const Spacer(),
          _buildNavItem(Icons.settings_rounded, 4, 'Settings'),
          const SizedBox(height: 30),
          _buildNavItem(Icons.logout_rounded, 5, 'Logout'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String tooltip) {
    final isSelected = widget.selectedIndex == index;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => widget.onItemTapped(index),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.iconActive : AppColors.iconInactive,
            size: 26,
          ),
        ),
      ),
    );
  }
}
