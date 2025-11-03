import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/view_tracking_entity.dart';

/// View tracking model for Firestore data
class ViewTrackingModel {
  final String id;
  final String contentId;
  final String contentType;
  final String studentId;
  final String studentName;
  final String action;
  final Timestamp timestamp;

  const ViewTrackingModel({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.studentId,
    required this.studentName,
    required this.action,
    required this.timestamp,
  });

  /// Convert to entity
  ViewTrackingEntity toEntity() {
    return ViewTrackingEntity(
      id: id,
      contentId: contentId,
      contentType: contentType,
      studentId: studentId,
      studentName: studentName,
      action: action,
      timestamp: timestamp.toDate(),
    );
  }

  /// Create from Firestore document
  factory ViewTrackingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ViewTrackingModel(
      id: doc.id,
      contentId: data['contentId'] as String,
      contentType: data['contentType'] as String,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      action: data['action'] as String,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'contentId': contentId,
      'contentType': contentType,
      'studentId': studentId,
      'studentName': studentName,
      'action': action,
      'timestamp': timestamp,
    };
  }
}
