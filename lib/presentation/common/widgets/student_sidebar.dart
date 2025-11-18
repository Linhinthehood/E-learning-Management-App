import 'package:flutter/material.dart';
import '../styles/colors.dart';

class StudentSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const StudentSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<StudentSidebar> createState() => _StudentSidebarState();
}

class _StudentSidebarState extends State<StudentSidebar> {
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
          const SizedBox(height: 30),
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
          const SizedBox(height: 40),
          // Navigation items
          _buildNavItem(Icons.home_rounded, 0, 'Home'),
          const SizedBox(height: 20),
          _buildNavItem(Icons.person_rounded, 1, 'Profile'),
          const Spacer(),
          _buildNavItem(Icons.logout_rounded, 2, 'Logout'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String tooltip) {
    final isSelected = widget.selectedIndex == index;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('Nav item tapped: index $index, tooltip: $tooltip');
            widget.onItemTapped(index);
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.3),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected ? AppColors.iconActive : AppColors.iconInactive,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
