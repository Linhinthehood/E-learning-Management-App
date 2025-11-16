import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/assignment_entity.dart';
import '../../../../domain/entities/quiz_entity.dart';
import '../../../../domain/entities/course_entity.dart';

/// Upcoming Deadlines Widget
class UpcomingDeadlinesWidget extends StatelessWidget {
  final List<AssignmentEntity> upcomingAssignments;
  final List<QuizEntity> upcomingQuizzes;
  final Map<String, CourseEntity> courseMap;
  final Function(CourseEntity course, String assignmentId)? onAssignmentTap;
  final Function(CourseEntity course, String quizId)? onQuizTap;

  const UpcomingDeadlinesWidget({
    super.key,
    required this.upcomingAssignments,
    required this.upcomingQuizzes,
    required this.courseMap,
    this.onAssignmentTap,
    this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    final allDeadlines = <_DeadlineItem>[];

    // Add assignments
    for (var assignment in upcomingAssignments) {
      allDeadlines.add(
        _DeadlineItem(
          id: assignment.id,
          courseId: assignment.courseId,
          title: assignment.title,
          deadline: assignment.deadline,
          type: _DeadlineType.assignment,
        ),
      );
    }

    // Add quizzes
    for (var quiz in upcomingQuizzes) {
      allDeadlines.add(
        _DeadlineItem(
          id: quiz.id,
          courseId: quiz.courseId,
          title: quiz.title,
          deadline: quiz.timeClose,
          type: _DeadlineType.quiz,
        ),
      );
    }

    // Sort by deadline
    allDeadlines.sort((a, b) => a.deadline.compareTo(b.deadline));

    if (allDeadlines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming deadlines',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: AppColors.buttonPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Upcoming Deadlines',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...allDeadlines
              .take(5)
              .map(
                (deadline) => _DeadlineItemWidget(
                  item: deadline,
                  onTap: () {
                    final course = courseMap[deadline.courseId];
                    if (course != null) {
                      if (deadline.type == _DeadlineType.assignment) {
                        onAssignmentTap?.call(course, deadline.id);
                      } else {
                        onQuizTap?.call(course, deadline.id);
                      }
                    }
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _DeadlineItem {
  final String id;
  final String courseId;
  final String title;
  final DateTime deadline;
  final _DeadlineType type;

  _DeadlineItem({
    required this.id,
    required this.courseId,
    required this.title,
    required this.deadline,
    required this.type,
  });
}

enum _DeadlineType { assignment, quiz }

class _DeadlineItemWidget extends StatelessWidget {
  final _DeadlineItem item;
  final VoidCallback onTap;

  const _DeadlineItemWidget({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = item.deadline.difference(now);
    final isUrgent = difference.inDays <= 1;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUrgent
              ? Colors.red.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent
                ? Colors.red.withValues(alpha: 0.3)
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.type == _DeadlineType.assignment
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.type == _DeadlineType.assignment
                    ? Icons.assignment
                    : Icons.quiz,
                color: item.type == _DeadlineType.assignment
                    ? Colors.orange
                    : Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(item.deadline),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Urgent',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
