import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/assignment_submission_entity.dart';
import '../../../../domain/entities/course_entity.dart';

/// Recent Grades Widget
class RecentGradesWidget extends StatelessWidget {
  final List<AssignmentSubmissionEntity> recentGrades;
  final Map<String, CourseEntity> courseMap;
  final Function(CourseEntity course, String assignmentId)? onTap;

  const RecentGradesWidget({
    super.key,
    required this.recentGrades,
    required this.courseMap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (recentGrades.isEmpty) {
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
              Icons.grade,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent grades',
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
              Icon(Icons.grade, color: AppColors.buttonPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Recent Grades',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...recentGrades
              .take(5)
              .map(
                (submission) => _GradeItemWidget(
                  submission: submission,
                  course: courseMap[submission.courseId],
                  onTap: () {
                    final course = courseMap[submission.courseId];
                    if (course != null) {
                      onTap?.call(course, submission.assignmentId);
                    }
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _GradeItemWidget extends StatelessWidget {
  final AssignmentSubmissionEntity submission;
  final CourseEntity? course;
  final VoidCallback onTap;

  const _GradeItemWidget({
    required this.submission,
    this.course,
    required this.onTap,
  });

  Color _getGradeColor(double grade) {
    if (grade >= 8.0) return Colors.green;
    if (grade >= 6.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final grade = submission.grade ?? 0.0;
    final gradeColor = _getGradeColor(grade);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.assignment, color: gradeColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course?.name ?? 'Assignment ${submission.attemptNumber}',
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
                    DateFormat(
                      'MMM dd, yyyy',
                    ).format(submission.submissionTime),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: gradeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                grade.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
