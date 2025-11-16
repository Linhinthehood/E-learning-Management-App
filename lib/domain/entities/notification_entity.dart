/// Notification entity for in-app notifications (Students only)
class NotificationEntity {
  final String id;
  final String studentId; // Recipient (only students receive notifications)
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String
  linkTo; // Deep-link to related content (e.g., "assignment/abc123", "quiz/xyz789")
  final String type; // announcement, assignment, quiz, grade, reminder, message

  const NotificationEntity({
    required this.id,
    required this.studentId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.linkTo,
    required this.type,
  });

  /// Notification types
  static const String typeAnnouncement = 'announcement';
  static const String typeAssignment = 'assignment';
  static const String typeQuiz = 'quiz';
  static const String typeGrade = 'grade';
  static const String typeReminder = 'reminder';
  static const String typeMessage = 'message';
}
