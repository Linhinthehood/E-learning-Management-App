import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/right_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/instructor_dashboard_provider.dart';
import 'widgets/instructor_statistics_cards.dart';
import 'widgets/instructor_activity_feed.dart';
import 'widgets/instructor_charts.dart';
import 'widgets/instructor_quick_actions.dart';

// Export CourseProgressData from right_sidebar
export '../../common/widgets/right_sidebar.dart' show CourseProgressData;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final dashboardAsync = ref.watch(instructorDashboardProvider(user.uid));

        return Row(
          children: [
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(user.displayName),
                    const SizedBox(height: 30),
                    // Dashboard Data
                    dashboardAsync.when(
                      data: (data) => _buildDashboardContent(data),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading dashboard data',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right Sidebar
            dashboardAsync.when(
              data: (data) => RightSidebar(
                totalCourses: data.statistics.totalCourses,
                totalStudents: data.statistics.totalStudents,
                courseProgressList: _buildCourseProgressList(data),
              ),
              loading: () => const RightSidebar(
                totalCourses: 0,
                totalStudents: 0,
                courseProgressList: [],
              ),
              error: (_, __) => const RightSidebar(
                totalCourses: 0,
                totalStudents: 0,
                courseProgressList: [],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }

  Widget _buildGreeting(String displayName) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello $displayName!',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Welcome to your instructor dashboard.",
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 30),
        // Illustration
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Text('👨‍🏫', style: TextStyle(fontSize: 60)),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(InstructorDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics Cards
        InstructorStatisticsCards(statistics: data.statistics),
        const SizedBox(height: 30),
        // Quick Actions
        const InstructorQuickActions(),
        const SizedBox(height: 30),
        // Charts
        InstructorCharts(
          submissionData: data.submissionChartData,
          quizScoreData: data.quizScoreChartData,
        ),
        const SizedBox(height: 30),
        // Recent Activity Feed
        InstructorActivityFeed(
          activities: data.recentActivities,
          courseMap: data.courseMap,
        ),
      ],
    );
  }

  List<CourseProgressData> _buildCourseProgressList(InstructorDashboardData data) {
    final courseProgressList = <CourseProgressData>[];
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
    ];

    int colorIndex = 0;

    // Calculate progress for each course
    // Progress is based on student engagement (submission rate + quiz participation)
    for (final courseEntry in data.courseMap.entries) {
      final course = courseEntry.value;

      // Count assignments and quizzes for this course from chart data
      final courseAssignments = data.submissionChartData
          .where((sub) => sub.assignmentTitle.isNotEmpty)
          .toList();

      final courseQuizzes = data.quizScoreChartData
          .where((quiz) => quiz.attempts > 0)
          .toList();

      // Calculate progress based on submission rate and quiz participation
      double progress;
      if (courseAssignments.isEmpty && courseQuizzes.isEmpty) {
        // No activities yet, show minimal progress
        progress = 0.15;
      } else {
        // Combine submission rate and quiz score as engagement metrics
        final submissionRate = data.statistics.averageSubmissionRate / 100;
        final quizScore = data.statistics.averageQuizScore / 100;

        // Average of both metrics (or just submission if no quizzes)
        if (courseQuizzes.isEmpty) {
          progress = submissionRate;
        } else if (courseAssignments.isEmpty) {
          progress = quizScore;
        } else {
          progress = (submissionRate + quizScore) / 2;
        }
      }

      courseProgressList.add(CourseProgressData(
        name: course.name,
        progress: progress.clamp(0.0, 1.0),
        color: colors[colorIndex % colors.length],
      ));

      colorIndex++;
    }

    return courseProgressList;
  }
}
