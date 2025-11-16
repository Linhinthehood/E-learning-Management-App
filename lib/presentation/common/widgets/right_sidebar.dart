import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../styles/colors.dart';

class CourseProgressData {
  final String name;
  final double progress;
  final Color color;

  CourseProgressData({
    required this.name,
    required this.progress,
    required this.color,
  });
}

class RightSidebar extends StatelessWidget {
  final int totalCourses;
  final int totalStudents;
  final List<CourseProgressData> courseProgressList;
  final String? firstCardLabel;
  final String? secondCardLabel;

  const RightSidebar({
    super.key,
    required this.totalCourses,
    required this.totalStudents,
    required this.courseProgressList,
    this.firstCardLabel,
    this.secondCardLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive width - prevents overflow on tablets and mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 1200
        ? 400.0
        : screenWidth > 900
        ? screenWidth * 0.35
        : screenWidth * 0.4;

    // Determine if we need compact layout
    final isCompact = sidebarWidth < 300;
    final padding = sidebarWidth < 250
        ? 12.0
        : (screenWidth < 900 ? 20.0 : 30.0);

    return Container(
      width: sidebarWidth,
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and profile - compact on narrow screens
          if (!isCompact)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 24),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            )
          else
            // Compact header for very narrow screens
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const Icon(Icons.notifications_outlined, size: 20),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 30),
          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  totalCourses.toString(),
                  firstCardLabel ?? 'Total\nCourses',
                  context,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  totalStudents.toString(),
                  secondCardLabel ?? 'Total\nStudents',
                  context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Statistics section
          Text(
            'Your statistics',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            'Course Progress',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Course Progress List
          if (courseProgressList.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: courseProgressList.length,
                itemBuilder: (context, index) {
                  final course = courseProgressList[index];
                  final progress = course.progress * 100;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                course.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${progress.toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: course.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: course.color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No courses yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: MediaQuery.of(context).size.width < 1200 ? 28 : 40,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
