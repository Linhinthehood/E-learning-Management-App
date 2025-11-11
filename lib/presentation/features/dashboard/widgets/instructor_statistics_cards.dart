import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/instructor_dashboard_provider.dart';

/// Statistics Cards Widget for Instructor Dashboard
class InstructorStatisticsCards extends StatelessWidget {
  final InstructorStatistics statistics;

  const InstructorStatisticsCards({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 2 rows on narrow, 1 row on wide
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.school,
                      title: 'Total Courses',
                      value: statistics.totalCourses.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      title: 'Total Students',
                      value: statistics.totalStudents.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.assignment,
                      title: 'Assignments',
                      value: statistics.totalAssignments.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.quiz,
                      title: 'Quizzes',
                      value: statistics.totalQuizzes.toString(),
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle,
                      title: 'Submission Rate',
                      value: '${statistics.averageSubmissionRate.toStringAsFixed(1)}%',
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up,
                      title: 'Avg Quiz Score',
                      value: '${statistics.averageQuizScore.toStringAsFixed(1)}%',
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // Wide layout: all in one row
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.school,
                title: 'Total Courses',
                value: statistics.totalCourses.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.people,
                title: 'Total Students',
                value: statistics.totalStudents.toString(),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.assignment,
                title: 'Assignments',
                value: statistics.totalAssignments.toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.quiz,
                title: 'Quizzes',
                value: statistics.totalQuizzes.toString(),
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                title: 'Submission Rate',
                value: '${statistics.averageSubmissionRate.toStringAsFixed(1)}%',
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up,
                title: 'Avg Quiz Score',
                value: '${statistics.averageQuizScore.toStringAsFixed(1)}%',
                color: Colors.pink,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
