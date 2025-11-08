/// Chat entity for private messaging between student and instructor
/// Document ID format: studentId_instructorId
class ChatEntity {
  final String id; // Format: studentId_instructorId
  final List<String> participantIds; // Always 2 IDs: [studentId, instructorId]
  final String studentId;
  final String instructorId;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final int unreadCountStudent; // Unread count for student
  final int unreadCountInstructor; // Unread count for instructor

  const ChatEntity({
    required this.id,
    required this.participantIds,
    required this.studentId,
    required this.instructorId,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    this.unreadCountStudent = 0,
    this.unreadCountInstructor = 0,
  });

  /// Get composite ID from student and instructor IDs
  static String getCompositeId(String studentId, String instructorId) {
    return '${studentId}_$instructorId';
  }

  /// Check if chat has unread messages for a given user
  bool hasUnreadFor(String userId) {
    if (userId == studentId) return unreadCountStudent > 0;
    if (userId == instructorId) return unreadCountInstructor > 0;
    return false;
  }
}
