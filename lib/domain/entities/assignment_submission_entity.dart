/// Assignment submission entity for student submissions
class AssignmentSubmissionEntity {
  final String id;
  final String assignmentId;
  final String studentId;
  final String courseId;
  final DateTime submissionTime;
  final List<String> files; // URLs of submitted files
  final int attemptNumber;
  final double? grade; // Set by instructor, null if not graded yet
  final String? feedback; // Instructor feedback
  final SubmissionStatus status;

  const AssignmentSubmissionEntity({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.courseId,
    required this.submissionTime,
    required this.files,
    required this.attemptNumber,
    this.grade,
    this.feedback,
    required this.status,
  });

  /// Check if submission is graded
  bool get isGraded => grade != null;

  /// Check if submission was late
  bool isLate(DateTime deadline) {
    return submissionTime.isAfter(deadline);
  }

  /// Check if submission is within late deadline
  bool isWithinLateDeadline(DateTime? lateDeadline) {
    if (lateDeadline == null) return false;
    return submissionTime.isBefore(lateDeadline);
  }
}

/// Submission status enum
enum SubmissionStatus {
  submitted, // Submitted on time
  late, // Submitted after deadline
  graded, // Graded by instructor
}

/// Extension to convert enum to string
extension SubmissionStatusExtension on SubmissionStatus {
  String get name {
    switch (this) {
      case SubmissionStatus.submitted:
        return 'submitted';
      case SubmissionStatus.late:
        return 'late';
      case SubmissionStatus.graded:
        return 'graded';
    }
  }

  /// Parse from string
  static SubmissionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'late':
        return SubmissionStatus.late;
      case 'graded':
        return SubmissionStatus.graded;
      default:
        return SubmissionStatus.submitted;
    }
  }
}
