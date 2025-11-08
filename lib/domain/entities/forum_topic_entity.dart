/// Forum topic entity for course-level discussions
class ForumTopicEntity {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final String authorId; // Can be instructor or student
  final List<String> attachments; // URLs or file paths
  final DateTime createdAt;
  final int replyCount; // Denormalized for performance

  const ForumTopicEntity({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.attachments,
    required this.createdAt,
    this.replyCount = 0,
  });

  /// Check if topic has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Check if topic has replies
  bool get hasReplies => replyCount > 0;
}
