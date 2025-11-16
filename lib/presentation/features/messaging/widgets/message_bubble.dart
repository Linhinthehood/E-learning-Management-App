import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/message_entity.dart';

/// Message Bubble Widget - displays a single message in the chat
class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isSent;
  final bool showAvatar;
  final String? participantName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    this.showAvatar = false,
    this.participantName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent && showAvatar) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.background,
              child: Text(
                participantName != null
                    ? participantName![0].toUpperCase()
                    : 'U',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isSent) ...[
            const SizedBox(width: 36), // Space for avatar when not showing
          ],
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isSent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isSent && participantName != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      participantName!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSent
                        ? AppColors.buttonPrimary
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSent ? 16 : 4),
                      bottomRight: Radius.circular(isSent ? 4 : 16),
                    ),
                    border: isSent
                        ? null
                        : Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isSent ? Colors.white : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isSent
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (isSent) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isRead ? Icons.done_all : Icons.done,
                              size: 12,
                              color: message.isRead
                                  ? Colors.blue.shade300
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isSent) ...[
            const SizedBox(width: 36), // Space for alignment
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
