import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Remote data source for notifications
/// Handles Firestore calls for notifications
abstract class NotificationRemoteDataSource {
  /// Get all notifications for a student
  Future<List<NotificationModel>> getNotificationsByStudent(String studentId);

  /// Get unread notifications for a student
  Future<List<NotificationModel>> getUnreadNotifications(String studentId);

  /// Get a single notification by ID
  Future<NotificationModel?> getNotificationById(String notificationId);

  /// Create a new notification
  Future<NotificationModel> createNotification(NotificationModel notification);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read for a student
  Future<void> markAllAsRead(String studentId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Get unread notification count for a student
  Future<int> getUnreadCount(String studentId);

  /// Listen to new notifications in real-time (returns stream)
  Stream<List<NotificationModel>> listenToNotifications(String studentId);

  /// Send notification to all students in a course
  Future<void> sendToAllStudentsInCourse(
    String courseId,
    String title,
    String message,
    String linkTo,
    String type,
  );

  /// Send notification to students in specific groups
  Future<void> sendToGroupStudents(
    List<String> groupIds,
    String title,
    String message,
    String linkTo,
    String type,
  );
}

/// Implementation of NotificationRemoteDataSource using Firestore
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<NotificationModel>> getNotificationsByStudent(
    String studentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('studentId', isEqualTo: studentId)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by createdAt descending (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    } catch (e) {
      throw Exception('Failed to get notifications: ${e.toString()}');
    }
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications(
    String studentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('studentId', isEqualTo: studentId)
          .where('isRead', isEqualTo: false)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by createdAt descending
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    } catch (e) {
      throw Exception('Failed to get unread notifications: ${e.toString()}');
    }
  }

  @override
  Future<NotificationModel?> getNotificationById(
    String notificationId,
  ) async {
    try {
      final docSnapshot = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return NotificationModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get notification: ${e.toString()}');
    }
  }

  @override
  Future<NotificationModel> createNotification(
    NotificationModel notification,
  ) async {
    try {
      final docRef = await _firestore
          .collection('notifications')
          .add(notification.toJson());

      final docSnapshot = await docRef.get();
      return NotificationModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  @override
  Future<void> markAllAsRead(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('studentId', isEqualTo: studentId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: ${e.toString()}');
    }
  }

  @override
  Future<int> getUnreadCount(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('studentId', isEqualTo: studentId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread count: ${e.toString()}');
    }
  }

  @override
  Stream<List<NotificationModel>> listenToNotifications(String studentId) {
    try {
      return _firestore
          .collection('notifications')
          .where('studentId', isEqualTo: studentId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to listen to notifications: ${e.toString()}');
    }
  }

  @override
  Future<void> sendToAllStudentsInCourse(
    String courseId,
    String title,
    String message,
    String linkTo,
    String type,
  ) async {
    try {
      // Get all enrollments for the course
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Extract unique student IDs
      final studentIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['studentId'] as String)
          .toSet()
          .toList();

      // Create notifications for all students
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (var studentId in studentIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        final notification = NotificationModel(
          id: notificationRef.id,
          studentId: studentId,
          title: title,
          message: message,
          isRead: false,
          createdAt: now,
          linkTo: linkTo,
          type: type,
        );

        batch.set(notificationRef, notification.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send notifications to course: ${e.toString()}');
    }
  }

  @override
  Future<void> sendToGroupStudents(
    List<String> groupIds,
    String title,
    String message,
    String linkTo,
    String type,
  ) async {
    try {
      // Get all enrollments for the specified groups
      final studentIds = <String>{};

      for (var groupId in groupIds) {
        final enrollmentsSnapshot = await _firestore
            .collection('enrollments')
            .where('groupId', isEqualTo: groupId)
            .get();

        for (var doc in enrollmentsSnapshot.docs) {
          studentIds.add(doc.data()['studentId'] as String);
        }
      }

      // Create notifications for all students
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (var studentId in studentIds) {
        final notificationRef = _firestore.collection('notifications').doc();
        final notification = NotificationModel(
          id: notificationRef.id,
          studentId: studentId,
          title: title,
          message: message,
          isRead: false,
          createdAt: now,
          linkTo: linkTo,
          type: type,
        );

        batch.set(notificationRef, notification.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send notifications to groups: ${e.toString()}');
    }
  }
}
