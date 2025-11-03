/// Comment entity for announcement comments
class CommentEntity {
  final String id;
  final String announcementId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommentEntity({
    required this.id,
    required this.announcementId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if comment was edited
  bool get wasEdited => updatedAt != null;
}
