import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/instructor_dashboard_provider.dart';
import '../../instructor/course_detail_screen.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../tracking/assignment_tracking_screen.dart';
import '../../tracking/quiz_tracking_screen.dart';
import '../../forum/forum_topic_detail_screen.dart';

/// Activity Feed Widget for Instructor Dashboard
class InstructorActivityFeed extends ConsumerWidget {
  final List<RecentActivity> activities;
  final Map<String, CourseEntity> courseMap;

  const InstructorActivityFeed({
    super.key,
    required this.activities,
    required this.courseMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...activities.map(
            (activity) => _ActivityItem(
              activity: activity,
              courseMap: courseMap,
              navigationService: ref.read(activityNavigationServiceProvider),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final RecentActivity activity;
  final Map<String, CourseEntity> courseMap;
  final ActivityNavigationService navigationService;

  const _ActivityItem({
    required this.activity,
    required this.courseMap,
    required this.navigationService,
  });

  IconData _getIcon() {
    switch (activity.type) {
      case 'submission':
        return Icons.assignment_turned_in;
      case 'quiz':
        return Icons.quiz;
      case 'forum':
        return Icons.forum;
      default:
        return Icons.circle;
    }
  }

  Color _getColor() {
    switch (activity.type) {
      case 'submission':
        return Colors.blue;
      case 'quiz':
        return Colors.purple;
      case 'forum':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel() {
    switch (activity.type) {
      case 'submission':
        return 'submitted';
      case 'quiz':
        return 'completed quiz';
      case 'forum':
        return 'posted in forum';
      default:
        return '';
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleActivityTap(BuildContext context) async {
    try {
      final result = await navigationService.resolve(activity, courseMap);
      if (result == null) {
        // Fallback to course detail if navigation fails
        final course = courseMap[activity.courseId];
        if (course != null) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InstructorCourseDetailScreen(
                  course: course,
                  initialTabIndex: _getTabIndex(),
                ),
              ),
            );
          }
        }
        return;
      }

      if (!context.mounted) return;

      if (result is AssignmentActivityNavigationResult) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentTrackingScreen(
              course: result.course,
              assignment: result.assignment,
            ),
          ),
        );
      } else if (result is QuizActivityNavigationResult) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                QuizTrackingScreen(course: result.course, quiz: result.quiz),
          ),
        );
      } else if (result is ForumActivityNavigationResult) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForumTopicDetailScreen(
              course: result.course,
              topicId: result.topicId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getTabIndex() {
    // Tab indexes: 0=Stream, 1=Assignments, 2=Quizzes, 3=Questions, 4=Materials, 5=Forum, 6=People
    switch (activity.type) {
      case 'submission':
        return 1; // Assignments tab
      case 'quiz':
        return 2; // Quizzes tab
      case 'forum':
        return 5; // Forum tab
      default:
        return 0; // Stream tab (default)
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final timeAgo = _getTimeAgo(activity.timestamp);

    return InkWell(
      onTap: () async {
        await _handleActivityTap(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getIcon(), color: color, size: 20),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: activity.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' ${_getTypeLabel()} '),
                        TextSpan(
                          text: activity.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.class_,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          activity.courseName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (activity.grade != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.grade, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          activity.grade!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
