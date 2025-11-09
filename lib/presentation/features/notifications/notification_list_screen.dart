import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/entities/user_entity.dart';
import 'widgets/notification_card.dart';
import '../../../utils/helpers/deep_link_handler.dart';
import 'package:intl/intl.dart';

/// Notification List Screen - displays all notifications for a student
class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  String _filterOption = 'all'; // all, unread

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = ref.read(authProvider).value;
        if (user != null && user.role == UserRole.student) {
          ref.read(notificationProvider.notifier).loadNotifications(user.uid);
        }
      }
    });
  }

  void _refreshNotifications() {
    final user = ref.read(authProvider).value;
    if (user != null && user.role == UserRole.student) {
      ref.read(notificationProvider.notifier).loadNotifications(user.uid);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _filterOption = filter;
    });

    final user = ref.read(authProvider).value;
    if (user != null && user.role == UserRole.student) {
      if (filter == 'unread') {
        ref
            .read(notificationProvider.notifier)
            .loadUnreadNotifications(user.uid);
      } else {
        ref.read(notificationProvider.notifier).loadNotifications(user.uid);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final user = ref.read(authProvider).value;
    if (user == null || user.role != UserRole.student) return;

    try {
      await ref
          .read(notificationProvider.notifier)
          .markAllAsRead(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null || user.role != UserRole.student) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Notifications',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            body: const Center(
              child: Text('Only students can view notifications'),
            ),
          );
        }

        final notificationsAsync = ref.watch(notificationStreamProvider(user.uid));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                onPressed: _refreshNotifications,
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter chips and Mark all as read
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterOption == 'all',
                      onSelected: (_) => _applyFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Unread'),
                      selected: _filterOption == 'unread',
                      onSelected: (_) => _applyFilter('unread'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all, size: 16),
                      label: Text(
                        'Mark all as read',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              // Notifications list
              Expanded(
                child: notificationsAsync.when(
                  data: (notifications) {
                    // Filter notifications based on selected filter
                    final filteredNotifications = _filterOption == 'unread'
                        ? notifications.where((n) => !n.isRead).toList()
                        : notifications;

                    if (filteredNotifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filterOption == 'unread'
                                  ? 'No unread notifications'
                                  : 'No notifications yet',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _filterOption == 'unread'
                                  ? 'You\'re all caught up!'
                                  : 'You\'ll see notifications here when they arrive',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group notifications by date
                    final groupedNotifications = _groupNotificationsByDate(filteredNotifications);

                    return RefreshIndicator(
                      onRefresh: () async {
                        _refreshNotifications();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: groupedNotifications.length,
                        itemBuilder: (context, index) {
                          final group = groupedNotifications[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date header
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  group['date'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              // Notifications for this date
                              ...(group['notifications'] as List<NotificationEntity>)
                                  .map((notification) => NotificationCard(
                                        notification: notification,
                                        onTap: () async {
                                          // Mark as read
                                          if (!notification.isRead) {
                                            await ref
                                                .read(notificationProvider.notifier)
                                                .markAsRead(notification.id);
                                          }

                                          // Handle deep link
                                          if (context.mounted) {
                                            await DeepLinkHandler.handleDeepLink(
                                              context,
                                              notification.linkTo,
                                            );
                                          }
                                        },
                                        onDelete: () {
                                          ref
                                              .read(notificationProvider.notifier)
                                              .deleteNotification(notification.id);
                                        },
                                      )),
                            ],
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notifications',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshNotifications,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text(
            'Error: ${error.toString()}',
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupNotificationsByDate(
    List<NotificationEntity> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationEntity>> grouped = {};

    for (var notification in notifications) {
      final notificationDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      String dateLabel;
      if (notificationDate == today) {
        dateLabel = 'Today';
      } else if (notificationDate == yesterday) {
        dateLabel = 'Yesterday';
      } else {
        dateLabel = DateFormat('MMMM d, yyyy').format(notification.createdAt);
      }

      grouped.putIfAbsent(dateLabel, () => []).add(notification);
    }

    // Sort by date (newest first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        if (a == 'Yesterday') return -1;
        if (b == 'Yesterday') return 1;
        return b.compareTo(a); // For other dates, sort descending
      });

    return sortedKeys.map((key) => {
      'date': key,
      'notifications': grouped[key]!..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      }).toList();
  }
}

