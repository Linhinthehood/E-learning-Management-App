/// User presence entity for tracking online/offline status
/// Stored as a document in the userPresence collection
class UserPresenceEntity {
  final String userId;
  final String status; // 'online', 'offline', 'away'
  final DateTime lastSeen;
  final bool isTyping; // For typing indicators in chat
  final String? typingInChatId; // Which chat the user is typing in (if any)

  const UserPresenceEntity({
    required this.userId,
    required this.status,
    required this.lastSeen,
    this.isTyping = false,
    this.typingInChatId,
  });

  /// Check if user is currently online
  bool get isOnline => status == 'online';

  /// Check if user was recently active (within last 5 minutes)
  bool get isRecentlyActive {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes < 5;
  }

  /// Copy with method for updating fields
  UserPresenceEntity copyWith({
    String? userId,
    String? status,
    DateTime? lastSeen,
    bool? isTyping,
    String? typingInChatId,
  }) {
    return UserPresenceEntity(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
      typingInChatId: typingInChatId ?? this.typingInChatId,
    );
  }
}
