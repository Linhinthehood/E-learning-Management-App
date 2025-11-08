import '../../../domain/entities/notification_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Notification
/// Used to convert between API/Database format and Entity
class NotificationModel {
  final String id;
  final String studentId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String linkTo;
  final String type;

  NotificationModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.linkTo,
    required this.type,
  });

  /// Convert from JSON (Firestore document)
  factory NotificationModel.fromJson(Map<String, dynamic> json, String id) {
    return NotificationModel(
      id: id,
      studentId: json['studentId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      linkTo: json['linkTo'] as String,
      type: json['type'] as String,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'linkTo': linkTo,
      'type': type,
    };
  }

  /// Convert to Entity (domain layer)
  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      studentId: studentId,
      title: title,
      message: message,
      isRead: isRead,
      createdAt: createdAt,
      linkTo: linkTo,
      type: type,
    );
  }

  /// Convert from Entity (domain layer)
  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      studentId: entity.studentId,
      title: entity.title,
      message: entity.message,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
      linkTo: entity.linkTo,
      type: entity.type,
    );
  }
}
