import '../../../domain/entities/chat_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Chat
/// Used to convert between API/Database format and Entity
class ChatModel {
  final String id;
  final List<String> participantIds;
  final String studentId;
  final String instructorId;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final int unreadCountStudent;
  final int unreadCountInstructor;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.studentId,
    required this.instructorId,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    this.unreadCountStudent = 0,
    this.unreadCountInstructor = 0,
  });

  /// Convert from JSON (Firestore document)
  factory ChatModel.fromJson(Map<String, dynamic> json, String id) {
    return ChatModel(
      id: id,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      studentId: json['studentId'] as String,
      instructorId: json['instructorId'] as String,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTimestamp: (json['lastMessageTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCountStudent: json['unreadCountStudent'] as int? ?? 0,
      unreadCountInstructor: json['unreadCountInstructor'] as int? ?? 0,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'studentId': studentId,
      'instructorId': instructorId,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
      'unreadCountStudent': unreadCountStudent,
      'unreadCountInstructor': unreadCountInstructor,
    };
  }

  /// Convert to Entity (domain layer)
  ChatEntity toEntity() {
    return ChatEntity(
      id: id,
      participantIds: participantIds,
      studentId: studentId,
      instructorId: instructorId,
      lastMessage: lastMessage,
      lastMessageTimestamp: lastMessageTimestamp,
      unreadCountStudent: unreadCountStudent,
      unreadCountInstructor: unreadCountInstructor,
    );
  }

  /// Convert from Entity (domain layer)
  factory ChatModel.fromEntity(ChatEntity entity) {
    return ChatModel(
      id: entity.id,
      participantIds: entity.participantIds,
      studentId: entity.studentId,
      instructorId: entity.instructorId,
      lastMessage: entity.lastMessage,
      lastMessageTimestamp: entity.lastMessageTimestamp,
      unreadCountStudent: entity.unreadCountStudent,
      unreadCountInstructor: entity.unreadCountInstructor,
    );
  }
}
