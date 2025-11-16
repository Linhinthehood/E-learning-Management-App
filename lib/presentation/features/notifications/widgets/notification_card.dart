import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/notification_entity.dart';

/// Notification Card Widget - displays a single notification
class NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationEntity.typeAnnouncement:
        return Icons.announcement;
      case NotificationEntity.typeAssignment:
        return Icons.assignment;
      case NotificationEntity.typeQuiz:
        return Icons.quiz;
      case NotificationEntity.typeGrade:
        return Icons.grade;
      case NotificationEntity.typeReminder:
        return Icons.alarm;
      case NotificationEntity.typeMessage:
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationEntity.typeAnnouncement:
        return Colors.blue;
      case NotificationEntity.typeAssignment:
        return Colors.orange;
      case NotificationEntity.typeQuiz:
        return Colors.purple;
      case NotificationEntity.typeGrade:
        return Colors.green;
      case NotificationEntity.typeReminder:
        return Colors.amber;
      case NotificationEntity.typeMessage:
        return Colors.teal;
      default:
        return AppColors.buttonPrimary;
    }
  }

  String _getNotificationTypeLabel() {
    switch (notification.type) {
      case NotificationEntity.typeAnnouncement:
        return 'Announcement';
      case NotificationEntity.typeAssignment:
        return 'Assignment';
      case NotificationEntity.typeQuiz:
        return 'Quiz';
      case NotificationEntity.typeGrade:
        return 'Grade';
      case NotificationEntity.typeReminder:
        return 'Reminder';
      case NotificationEntity.typeMessage:
        return 'Message';
      default:
        return 'Notification';
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getNotificationColor();
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isUnread
            ? AppColors.buttonPrimary.withValues(alpha: 0.05)
            : AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isUnread
                ? AppColors.buttonPrimary.withValues(alpha: 0.3)
                : AppColors.border,
            width: isUnread ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(),
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(notification.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getNotificationTypeLabel(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: iconColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Message
                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isUnread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.buttonPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
