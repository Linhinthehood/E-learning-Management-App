import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/left_sidebar.dart';
import '../../common/widgets/right_sidebar.dart';
import '../../common/widgets/course_list_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Sidebar
          const LeftSidebar(),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 30),
                    _buildFeaturedCourse(),
                    const SizedBox(height: 40),
                    _buildCoursesSection(),
                  ],
                ),
              ),
            ),
          ),
          // Right Sidebar
          const RightSidebar(),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello Josh!',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "It's good to see you again.",
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 30),
        // Illustration placeholder
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Text(
              '👋',
              style: TextStyle(fontSize: 60),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCourse() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                '🇪🇸',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spanish B2',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'by Alejandro Velazquez',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, size: 20),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesSection() {
    final courses = [
      {
        'title': 'Learn Figma',
        'instructor': 'Christopher Morgan',
        'duration': '6h 30min',
        'rating': 4.0,
        'icon': Icons.design_services,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'title': 'Analog photography',
        'instructor': 'Gordon Norman',
        'duration': '3h 15min',
        'rating': 4.7,
        'icon': Icons.camera_alt,
        'color': const Color(0xFF4ECDC4),
      },
      {
        'title': 'Master Instagram',
        'instructor': 'Sophie Gill',
        'duration': '7h 40min',
        'rating': 4.6,
        'icon': Icons.photo_camera,
        'color': const Color(0xFFE056FD),
      },
      {
        'title': 'Basics of drawing',
        'instructor': 'Jean Tate',
        'duration': '11h 30min',
        'rating': 4.8,
        'icon': Icons.brush,
        'color': const Color(0xFFFFA726),
      },
      {
        'title': 'Photoshop - Essence',
        'instructor': 'David Green',
        'duration': '5h 35min',
        'rating': 4.7,
        'icon': Icons.photo,
        'color': const Color(0xFF42A5F5),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Courses',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        // Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTab('All Courses', 0),
              const SizedBox(width: 30),
              _buildTab('Courses This Semester', 1),
              const SizedBox(width: 30),
              _buildTab('Need Homework Courses', 2),
              const SizedBox(width: 30),
              _buildTab('Course With Upcoming Test', 3),
            ],
          ),
        ),
        const SizedBox(height: 25),
        // Course list
        ...courses.map((course) => CourseListItem(
              title: course['title'] as String,
              instructor: course['instructor'] as String,
              duration: course['duration'] as String,
              rating: course['rating'] as double,
              icon: course['icon'] as IconData,
              iconColor: course['color'] as Color,
            )),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
