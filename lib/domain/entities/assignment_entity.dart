/// Assignment entity for course assignments
class AssignmentEntity {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final List<String> scopedGroupIds; // Empty = all groups
  final DateTime startDate;
  final DateTime deadline;
  final DateTime? lateDeadline; // Optional late submission deadline
  final int maxAttempts; // 0 = unlimited
  final List<String> allowedFileFormats; // e.g., ['pdf', 'doc', 'docx']
  final int maxFileSizeMB; // Maximum file size in MB
  final DateTime createdAt;

  const AssignmentEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.scopedGroupIds,
    required this.startDate,
    required this.deadline,
    this.lateDeadline,
    required this.maxAttempts,
    required this.allowedFileFormats,
    required this.maxFileSizeMB,
    required this.createdAt,
  });

  /// Check if assignment is for all groups
  bool get isForAllGroups => scopedGroupIds.isEmpty;

  /// Check if assignment allows late submissions
  bool get allowsLateSubmission => lateDeadline != null;

  /// Check if assignment has unlimited attempts
  bool get hasUnlimitedAttempts => maxAttempts == 0;

  /// Check if assignment is currently open
  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(deadline);
  }

  /// Check if assignment is accepting late submissions
  bool get isAcceptingLateSubmissions {
    if (lateDeadline == null) return false;
    final now = DateTime.now();
    return now.isAfter(deadline) && now.isBefore(lateDeadline!);
  }

  /// Check if assignment is closed
  bool get isClosed {
    final now = DateTime.now();
    if (lateDeadline != null) {
      return now.isAfter(lateDeadline!);
    }
    return now.isAfter(deadline);
  }
}
