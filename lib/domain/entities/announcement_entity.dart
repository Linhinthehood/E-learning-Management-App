/// Announcement entity for course announcements
class AnnouncementEntity {
  final String id;
  final String title;
  final String content;
  final List<String> attachments; // URLs or file paths
  final String courseId;
  final String authorId; // Instructor ID
  final List<String> scopedGroupIds; // Empty = all groups
  final DateTime createdAt;

  const AnnouncementEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.attachments,
    required this.courseId,
    required this.authorId,
    required this.scopedGroupIds,
    required this.createdAt,
  });

  /// Check if announcement is for all groups
  bool get isForAllGroups => scopedGroupIds.isEmpty;

  /// Check if announcement has attachments
  bool get hasAttachments => attachments.isNotEmpty;
}
