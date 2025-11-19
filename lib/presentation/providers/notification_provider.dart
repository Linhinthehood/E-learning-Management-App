import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/quiz_entity.dart';
import '../../domain/entities/material_entity.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../../domain/repositories/i_assignment_repository.dart';
import '../../domain/repositories/i_quiz_repository.dart';
import '../../domain/repositories/i_material_repository.dart';
import '../../domain/repositories/i_chat_repository.dart';
import 'course_provider.dart';
import 'assignment_provider.dart';
import 'quiz_provider.dart';
import 'material_provider.dart';
import 'chat_provider.dart';

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
      final notifications = await _repository.getNotificationsByStudent(
        studentId,
      );
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
      final notifications = await _repository.getUnreadNotifications(studentId);
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
final notificationProvider =
    StateNotifierProvider<
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
    StreamProvider.family<List<NotificationEntity>, String>((ref, studentId) {
      final repository = ref.read(notificationRepositoryProvider);
      return repository.listenToNotifications(studentId);
    });

/// Navigation result base class for notifications
abstract class NotificationNavigationResult {}

class AssignmentNavigationResult extends NotificationNavigationResult {
  final CourseEntity course;
  final AssignmentEntity assignment;

  AssignmentNavigationResult({
    required this.course,
    required this.assignment,
  });
}

class QuizNavigationResult extends NotificationNavigationResult {
  final CourseEntity course;
  final QuizEntity quiz;

  QuizNavigationResult({
    required this.course,
    required this.quiz,
  });
}

class MaterialNavigationResult extends NotificationNavigationResult {
  final CourseEntity course;
  final MaterialEntity material;

  MaterialNavigationResult({
    required this.course,
    required this.material,
  });
}

class CourseTabNavigationResult extends NotificationNavigationResult {
  final CourseEntity course;
  final int initialTabIndex;

  CourseTabNavigationResult({
    required this.course,
    required this.initialTabIndex,
  });
}

class ForumNavigationResult extends NotificationNavigationResult {
  final CourseEntity course;

  ForumNavigationResult({required this.course});
}

class MessageNavigationResult extends NotificationNavigationResult {
  final String chatId;
  final String participantId;
  final String participantName;

  MessageNavigationResult({
    required this.chatId,
    required this.participantId,
    required this.participantName,
  });
}

/// Service that converts notification deep links to navigation targets
class NotificationNavigationService {
  NotificationNavigationService({
    required ICourseRepository courseRepository,
    required IAssignmentRepository assignmentRepository,
    required IQuizRepository quizRepository,
    required IMaterialRepository materialRepository,
    required IChatRepository chatRepository,
  })  : _courseRepository = courseRepository,
        _assignmentRepository = assignmentRepository,
        _quizRepository = quizRepository,
        _materialRepository = materialRepository,
        _chatRepository = chatRepository;

  final ICourseRepository _courseRepository;
  final IAssignmentRepository _assignmentRepository;
  final IQuizRepository _quizRepository;
  final IMaterialRepository _materialRepository;
  final IChatRepository _chatRepository;

  Future<NotificationNavigationResult?> resolve(
    NotificationEntity notification,
  ) async {
    final linkTo = notification.linkTo;
    if (linkTo.isEmpty) return null;

    final parts = linkTo.split('/');
    if (parts.isEmpty) return null;

    final linkType = parts[0];

    switch (linkType) {
      case 'assignment':
        if (parts.length < 3) return null;
        final course = await _courseRepository.getCourseById(parts[1]);
        final assignment = await _assignmentRepository.getAssignmentById(
          parts[2],
        );
        if (course == null || assignment == null) return null;
        return AssignmentNavigationResult(course: course, assignment: assignment);

      case 'quiz':
        if (parts.length < 3) return null;
        final course = await _courseRepository.getCourseById(parts[1]);
        final quiz = await _quizRepository.getQuizById(parts[2]);
        if (course == null || quiz == null) return null;
        return QuizNavigationResult(course: course, quiz: quiz);

      case 'material':
        if (parts.length < 3) return null;
        final course = await _courseRepository.getCourseById(parts[1]);
        final material = await _materialRepository.getMaterialById(parts[2]);
        if (course == null || material == null) return null;
        return MaterialNavigationResult(course: course, material: material);

      case 'announcement':
        if (parts.length < 2) return null;
        final course = await _courseRepository.getCourseById(parts[1]);
        if (course == null) return null;
        return CourseTabNavigationResult(course: course, initialTabIndex: 0);

      case 'forum':
        if (parts.length < 2) return null;
        final course = await _courseRepository.getCourseById(parts[1]);
        if (course == null) return null;
        return ForumNavigationResult(course: course);

      case 'message':
        if (parts.length < 2) return null;
        final chat = await _chatRepository.getChatById(parts[1]);
        if (chat == null) return null;
        final instructorInfo =
            await _courseRepository.getInstructorInfo(chat.instructorId);
        final participantName =
            instructorInfo?['displayName'] ?? 'Instructor';
        return MessageNavigationResult(
          chatId: chat.id,
          participantId: chat.instructorId,
          participantName: participantName,
        );

      default:
        return null;
    }
  }
}

/// Provider exposing navigation resolver for notifications
final notificationNavigationServiceProvider =
    Provider<NotificationNavigationService>((ref) {
  return NotificationNavigationService(
    courseRepository: ref.read(courseRepositoryProvider),
    assignmentRepository: ref.read(assignmentRepositoryProvider),
    quizRepository: ref.read(quizRepositoryProvider),
    materialRepository: ref.read(materialRepositoryProvider),
    chatRepository: ref.read(chatRepositoryProvider),
  );
});
