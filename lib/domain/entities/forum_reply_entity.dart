/// Forum reply entity for responses to forum topics
class ForumReplyEntity {
  final String id;
  final String topicId; // Reference to the forum topic
  final String content;
  final String authorId; // Can be instructor or student
  final DateTime createdAt;
  final String? replyToId; // Optional: for threaded replies (reply to another reply)

  const ForumReplyEntity({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.replyToId,
  });

  /// Check if this is a threaded reply (reply to another reply)
  bool get isThreadedReply => replyToId != null;
}
