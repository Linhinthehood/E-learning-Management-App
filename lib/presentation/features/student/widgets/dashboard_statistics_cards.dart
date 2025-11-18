import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/student_dashboard_provider.dart';

/// Statistics Cards Widget for Student Dashboard
class DashboardStatisticsCards extends StatelessWidget {
  final Statistics statistics;

  const DashboardStatisticsCards({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // Horizontal scrollable cards on mobile
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatCard(
              icon: Icons.school,
              title: 'Courses',
              value: statistics.totalCourses.toString(),
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.assignment,
              title: 'Pending',
              subtitle: 'Assignments',
              value: statistics.pendingAssignments.toString(),
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.quiz,
              title: 'Upcoming',
              subtitle: 'Quizzes',
              value: statistics.upcomingQuizzes.toString(),
              color: Colors.purple,
            ),
            const SizedBox(width: 12),
            _StatCard(
              icon: Icons.grade,
              title: 'Average',
              subtitle: 'Grade',
              value: statistics.overallAverage.toStringAsFixed(1),
              color: Colors.green,
            ),
          ],
        ),
      );
    }

    // Regular row layout for larger screens
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.school,
            title: 'Courses',
            value: statistics.totalCourses.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.assignment,
            title: 'Pending Assignments',
            value: statistics.pendingAssignments.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.quiz,
            title: 'Upcoming Quizzes',
            value: statistics.upcomingQuizzes.toString(),
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.grade,
            title: 'Average Grade',
            value: statistics.overallAverage.toStringAsFixed(1),
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isMobile ? 130 : null,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (subtitle != null) ...[
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ] else
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: isMobile ? 11 : 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
