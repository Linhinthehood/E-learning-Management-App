import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/skeleton_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/instructor_dashboard_provider.dart';
import 'widgets/instructor_statistics_cards.dart';
import 'widgets/instructor_activity_feed.dart';
import 'widgets/instructor_charts.dart';

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

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(user.displayName),
              const SizedBox(height: 30),
              // Dashboard Data
              dashboardAsync.when(
                data: (data) => _buildDashboardContent(data),
                loading: () => const SkeletonDashboardContent(),
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
        );
      },
      loading: () => const SkeletonDashboardContent(),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }

  Widget _buildGreeting(String displayName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello $displayName!',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 20 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Welcome to your instructor dashboard.",
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 12 : 15,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            // Show illustration only on wider screens
            if (!isMobile) ...[
              const SizedBox(width: 30),
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
          ],
        );
      },
    );
  }

  Widget _buildDashboardContent(InstructorDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistics Cards
        InstructorStatisticsCards(statistics: data.statistics),
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
}
