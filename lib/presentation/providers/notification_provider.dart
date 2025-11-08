import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_notification_repository.dart';

/// Provider for notification remote data source
final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceImpl();
});

/// Provider for notification repository
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    remoteDataSource: ref.read(notificationRemoteDataSourceProvider),
  );
});

/// Notification state notifier - manages notifications for a student
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationEntity>>> {
  final INotificationRepository _repository;
  String? _currentStudentId;

  NotificationNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load notifications for a student
  Future<void> loadNotifications(String studentId) async {
    _currentStudentId = studentId;
    state = const AsyncValue.loading();
    try {
      final notifications =
          await _repository.getNotificationsByStudent(studentId);
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load unread notifications for a student
  Future<void> loadUnreadNotifications(String studentId) async {
    _currentStudentId = studentId;
    state = const AsyncValue.loading();
    try {
      final notifications =
          await _repository.getUnreadNotifications(studentId);
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new notification
  Future<void> createNotification(NotificationEntity notification) async {
    try {
      await _repository.createNotification(notification);
      if (_currentStudentId != null) {
        await loadNotifications(_currentStudentId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      if (_currentStudentId != null) {
        await loadNotifications(_currentStudentId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all notifications as read for a student
  Future<void> markAllAsRead(String studentId) async {
    try {
      await _repository.markAllAsRead(studentId);
      if (_currentStudentId != null) {
        await loadNotifications(_currentStudentId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      if (_currentStudentId != null) {
        await loadNotifications(_currentStudentId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send notification to all students in a course
  Future<void> sendToAllStudentsInCourse(
    String courseId,
    String title,
    String message,
    String linkTo,
    String type,
  ) async {
    try {
      await _repository.sendToAllStudentsInCourse(
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

  /// Send notification to students in specific groups
  Future<void> sendToGroupStudents(
    List<String> groupIds,
    String title,
    String message,
    String linkTo,
    String type,
  ) async {
    try {
      await _repository.sendToGroupStudents(
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

  /// Refresh current notifications
  Future<void> refresh() async {
    if (_currentStudentId != null) {
      await loadNotifications(_currentStudentId!);
    }
  }
}

/// Provider for notification state notifier
final notificationProvider = StateNotifierProvider<
    NotificationNotifier,
    AsyncValue<List<NotificationEntity>>
>((ref) {
  return NotificationNotifier(ref.read(notificationRepositoryProvider));
});

/// Provider for fetching a single notification by ID
final notificationByIdProvider =
    FutureProvider.family<NotificationEntity?, String>((
  ref,
  notificationId,
) async {
  final repository = ref.read(notificationRepositoryProvider);
  return await repository.getNotificationById(notificationId);
});

/// Provider for unread notification count
final unreadNotificationCountProvider = FutureProvider.family<int, String>((
  ref,
  studentId,
) async {
  final repository = ref.read(notificationRepositoryProvider);
  return await repository.getUnreadCount(studentId);
});

/// Provider for real-time notification stream
final notificationStreamProvider =
    StreamProvider.family<List<NotificationEntity>, String>((
  ref,
  studentId,
) {
  final repository = ref.read(notificationRepositoryProvider);
  return repository.listenToNotifications(studentId);
});
