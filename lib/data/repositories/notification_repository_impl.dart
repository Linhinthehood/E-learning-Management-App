import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../datasources/remote/notification_remote_datasource.dart';
import '../datasources/models/notification_model.dart';

/// Implementation of INotificationRepository
/// Handles conversion between models and entities
class NotificationRepositoryImpl implements INotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<NotificationEntity>> getNotificationsByStudent(
    String studentId,
  ) async {
    try {
      final notificationModels =
          await remoteDataSource.getNotificationsByStudent(studentId);
      return notificationModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<NotificationEntity>> getUnreadNotifications(
    String studentId,
  ) async {
    try {
      final notificationModels =
          await remoteDataSource.getUnreadNotifications(studentId);
      return notificationModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<NotificationEntity?> getNotificationById(
    String notificationId,
  ) async {
    try {
      final notificationModel =
          await remoteDataSource.getNotificationById(notificationId);
      return notificationModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<NotificationEntity> createNotification(
    NotificationEntity notification,
  ) async {
    try {
      final notificationModel = NotificationModel.fromEntity(notification);
      final createdModel =
          await remoteDataSource.createNotification(notificationModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String studentId) async {
    try {
      await remoteDataSource.markAllAsRead(studentId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await remoteDataSource.deleteNotification(notificationId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String studentId) async {
    try {
      return await remoteDataSource.getUnreadCount(studentId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<NotificationEntity>> listenToNotifications(String studentId) {
    try {
      return remoteDataSource.listenToNotifications(studentId).map(
            (notificationModels) =>
                notificationModels.map((model) => model.toEntity()).toList(),
          );
    } catch (e) {
      rethrow;
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
      await remoteDataSource.sendToAllStudentsInCourse(
        courseId,
        title,
        message,
        linkTo,
        type,
      );
    } catch (e) {
      rethrow;
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
      await remoteDataSource.sendToGroupStudents(
        groupIds,
        title,
        message,
        linkTo,
        type,
      );
    } catch (e) {
      rethrow;
    }
  }
}
