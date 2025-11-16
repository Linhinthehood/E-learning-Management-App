import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/quiz_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_assignment_repository.dart';
import '../../domain/repositories/i_quiz_repository.dart';
import '../../domain/repositories/i_notification_repository.dart';

/// Service to check and send deadline reminder notifications
/// Sends notifications 24 hours before assignment/quiz deadlines
class DeadlineReminderService {
  final IAssignmentRepository assignmentRepository;
  final IQuizRepository quizRepository;
  final INotificationRepository notificationRepository;
  final FirebaseFirestore firestore;

  DeadlineReminderService({
    required this.assignmentRepository,
    required this.quizRepository,
    required this.notificationRepository,
    required this.firestore,
  });

  /// Check and send deadline reminders for a specific student
  /// This should be called when the student opens the app or views their dashboard
  Future<void> checkAndSendReminders(String studentId) async {
    try {
      // Get all courses the student is enrolled in by querying Firestore directly
      final enrollmentsSnapshot = await firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .get();

      final courseIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toList();

      if (courseIds.isEmpty) return;

      // Check assignments and quizzes for each course
      for (final courseId in courseIds) {
        await _checkAssignmentReminders(courseId, studentId);
        await _checkQuizReminders(courseId, studentId);
      }
    } catch (e) {
      debugPrint('Error checking deadline reminders: $e');
      // Don't throw - this is a background task
    }
  }

  /// Check and send assignment deadline reminders
  Future<void> _checkAssignmentReminders(
    String courseId,
    String studentId,
  ) async {
    try {
      // Get all assignments for the course
      final assignments = await assignmentRepository.getAssignmentsByCourse(
        courseId,
      );

      final now = DateTime.now();
      final reminderWindow = now.add(const Duration(hours: 24));

      for (final assignment in assignments) {
        // Skip if assignment is not for this student's groups
        // (Simplified - in production, check student's group membership)

        // Check if deadline is within the next 24 hours
        final deadline = assignment.deadline;
        if (deadline.isAfter(now) && deadline.isBefore(reminderWindow)) {
          // Check if reminder already sent
          final reminderSent = await _isReminderSent(
            studentId,
            assignment.id,
            'assignment',
          );

          if (!reminderSent) {
            // Send reminder notification
            await _sendAssignmentReminder(studentId, assignment, courseId);
            // Mark reminder as sent
            await _markReminderSent(studentId, assignment.id, 'assignment');
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Error checking assignment reminders for course $courseId: $e',
      );
    }
  }

  /// Check and send quiz deadline reminders
  Future<void> _checkQuizReminders(String courseId, String studentId) async {
    try {
      // Get all quizzes for the course
      final quizzes = await quizRepository.getQuizzesByCourse(courseId);

      final now = DateTime.now();
      final reminderWindow = now.add(const Duration(hours: 24));

      for (final quiz in quizzes) {
        // Check if close time is within the next 24 hours
        final closeTime = quiz.timeClose;
        if (closeTime.isAfter(now) && closeTime.isBefore(reminderWindow)) {
          // Check if reminder already sent
          final reminderSent = await _isReminderSent(
            studentId,
            quiz.id,
            'quiz',
          );

          if (!reminderSent) {
            // Send reminder notification
            await _sendQuizReminder(studentId, quiz, courseId);
            // Mark reminder as sent
            await _markReminderSent(studentId, quiz.id, 'quiz');
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking quiz reminders for course $courseId: $e');
    }
  }

  /// Send assignment deadline reminder notification
  Future<void> _sendAssignmentReminder(
    String studentId,
    AssignmentEntity assignment,
    String courseId,
  ) async {
    try {
      final timeUntilDeadline = assignment.deadline.difference(DateTime.now());
      final hoursRemaining = timeUntilDeadline.inHours;

      final notification = NotificationEntity(
        id: '', // Firestore will generate
        studentId: studentId,
        title: 'Assignment Deadline Reminder',
        message:
            'Reminder: Assignment "${assignment.title}" is due in $hoursRemaining hours!',
        isRead: false,
        createdAt: DateTime.now(),
        linkTo: 'assignment/$courseId/${assignment.id}',
        type: NotificationEntity.typeReminder,
      );

      await notificationRepository.createNotification(notification);
      debugPrint(
        'Sent assignment reminder for ${assignment.title} to student $studentId',
      );
    } catch (e) {
      debugPrint('Error sending assignment reminder: $e');
    }
  }

  /// Send quiz deadline reminder notification
  Future<void> _sendQuizReminder(
    String studentId,
    QuizEntity quiz,
    String courseId,
  ) async {
    try {
      final timeUntilDeadline = quiz.timeClose.difference(DateTime.now());
      final hoursRemaining = timeUntilDeadline.inHours;

      final notification = NotificationEntity(
        id: '', // Firestore will generate
        studentId: studentId,
        title: 'Quiz Deadline Reminder',
        message:
            'Reminder: Quiz "${quiz.title}" closes in $hoursRemaining hours!',
        isRead: false,
        createdAt: DateTime.now(),
        linkTo: 'quiz/$courseId/${quiz.id}',
        type: NotificationEntity.typeReminder,
      );

      await notificationRepository.createNotification(notification);
      debugPrint('Sent quiz reminder for ${quiz.title} to student $studentId');
    } catch (e) {
      debugPrint('Error sending quiz reminder: $e');
    }
  }

  /// Check if a reminder has already been sent
  Future<bool> _isReminderSent(
    String studentId,
    String itemId,
    String itemType,
  ) async {
    try {
      final doc = await firestore
          .collection('deadlineReminders')
          .doc('${studentId}_${itemType}_$itemId')
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if reminder sent: $e');
      return false; // Assume not sent if error
    }
  }

  /// Mark a reminder as sent to avoid duplicates
  Future<void> _markReminderSent(
    String studentId,
    String itemId,
    String itemType,
  ) async {
    try {
      await firestore
          .collection('deadlineReminders')
          .doc('${studentId}_${itemType}_$itemId')
          .set({
            'studentId': studentId,
            'itemId': itemId,
            'itemType': itemType,
            'sentAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error marking reminder as sent: $e');
    }
  }

  /// Clean up old reminder records (call periodically)
  /// Removes records older than 7 days
  Future<void> cleanupOldReminders() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await firestore
          .collection('deadlineReminders')
          .where('sentAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('Cleaned up ${snapshot.docs.length} old reminder records');
    } catch (e) {
      debugPrint('Error cleaning up old reminders: $e');
    }
  }
}
