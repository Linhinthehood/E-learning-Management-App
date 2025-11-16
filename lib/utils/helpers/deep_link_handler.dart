import 'package:flutter/material.dart';
import '../../presentation/features/course/course_detail_screen.dart';
import '../../presentation/features/messaging/chat_screen.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/datasources/remote/course_remote_datasource.dart';
import '../../data/datasources/remote/chat_remote_datasource.dart';

/// Deep Link Handler - handles navigation based on linkTo from notifications
class DeepLinkHandler {
  /// Handle deep link navigation
  /// linkTo format: "type/courseId/id" or "type/id"
  /// Examples:
  /// - "announcement/course123/announce456"
  /// - "assignment/course123/assign456"
  /// - "quiz/course123/quiz789"
  /// - "material/course123/material456"
  /// - "forum/course123/topic789"
  /// - "message/chatId"
  static Future<void> handleDeepLink(
    BuildContext context,
    String linkTo,
  ) async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final parts = linkTo.split('/');
      if (parts.isEmpty) {
        debugPrint('Empty deep link: $linkTo');
        return;
      }

      final type = parts[0];

      switch (type) {
        case 'announcement':
        case 'assignment':
        case 'quiz':
        case 'material':
        case 'forum':
          // These all navigate to course detail screen
          await _handleCourseContentLink(context, type, parts);
          break;

        case 'message':
          // Navigate to chat screen
          await _handleMessageLink(context, parts);
          break;

        default:
          debugPrint('Unknown deep link type: $type');
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Unknown notification type: $type'),
                backgroundColor: Colors.orange,
              ),
            );
          }
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error opening notification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle deep links for course-related content
  static Future<void> _handleCourseContentLink(
    BuildContext context,
    String type,
    List<String> parts,
  ) async {
    if (!context.mounted) return;

    if (parts.length < 2) {
      debugPrint('Invalid course content link: ${parts.join('/')}');
      return;
    }

    final courseId = parts[1];

    try {
      // Get course data
      final courseRepo = CourseRepositoryImpl(
        remoteDataSource: CourseRemoteDataSourceImpl(),
      );
      final course = await courseRepo.getCourseById(courseId);

      if (course == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Navigate to course detail screen
      // Note: User can navigate to the appropriate tab manually
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetailScreen(course: course),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to course content: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading course: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle deep links for messages
  static Future<void> _handleMessageLink(
    BuildContext context,
    List<String> parts,
  ) async {
    if (!context.mounted) return;

    if (parts.length < 2) {
      debugPrint('Invalid message link: ${parts.join('/')}');
      return;
    }

    final chatId = parts[1];

    try {
      // Get chat data
      final chatRepo = ChatRepositoryImpl(
        remoteDataSource: ChatRemoteDataSourceImpl(),
      );
      final chat = await chatRepo.getChatById(chatId);

      if (chat == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Determine participant info (assume we are the student viewing the chat)
      // In a real app, we'd get the current user ID and determine which participant is "other"
      final participantId = chat.instructorId;
      const participantName =
          'Instructor'; // Simplified - in real app, fetch from user data

      // Navigate to chat screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chat.id,
            participantId: participantId,
            participantName: participantName,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to chat: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
