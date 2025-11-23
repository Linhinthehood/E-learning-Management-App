import '../../../domain/entities/user_presence_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for UserPresence
/// Used to convert between API/Database format and Entity
class UserPresenceModel {
  final String userId;
  final String status;
  final DateTime lastSeen;
  final bool isTyping;
  final String? typingInChatId;

  UserPresenceModel({
    required this.userId,
    required this.status,
    required this.lastSeen,
    this.isTyping = false,
    this.typingInChatId,
  });

  /// Convert from JSON (Firestore document)
  factory UserPresenceModel.fromJson(Map<String, dynamic> json, String id) {
    return UserPresenceModel(
      userId: id,
      status: json['status'] as String? ?? 'offline',
      lastSeen: (json['lastSeen'] as Timestamp).toDate(),
      isTyping: json['isTyping'] as bool? ?? false,
      typingInChatId: json['typingInChatId'] as String?,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isTyping': isTyping,
      'typingInChatId': typingInChatId,
    };
  }

  /// Convert to Entity (domain layer)
  UserPresenceEntity toEntity() {
    return UserPresenceEntity(
      userId: userId,
      status: status,
      lastSeen: lastSeen,
      isTyping: isTyping,
      typingInChatId: typingInChatId,
    );
  }

  /// Convert from Entity (domain layer)
  factory UserPresenceModel.fromEntity(UserPresenceEntity entity) {
    return UserPresenceModel(
      userId: entity.userId,
      status: entity.status,
      lastSeen: entity.lastSeen,
      isTyping: entity.isTyping,
      typingInChatId: entity.typingInChatId,
    );
  }
}
