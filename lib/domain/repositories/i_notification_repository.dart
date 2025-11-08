import '../entities/notification_entity.dart';

/// Notification repository interface
/// This defines the contract that data layer must implement
abstract class INotificationRepository {
  /// Get all notifications for a student
  Future<List<NotificationEntity>> getNotificationsByStudent(String studentId);

  /// Get unread notifications for a student
  Future<List<NotificationEntity>> getUnreadNotifications(String studentId);

  /// Get a single notification by ID
  Future<NotificationEntity?> getNotificationById(String notificationId);

  /// Create a new notification
  Future<NotificationEntity> createNotification(
    NotificationEntity notification,
  );

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read for a student
  Future<void> markAllAsRead(String studentId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Get unread notification count for a student
  Future<int> getUnreadCount(String studentId);

  /// Listen to new notifications in real-time (returns stream)
  Stream<List<NotificationEntity>> listenToNotifications(String studentId);

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
