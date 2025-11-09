import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../../domain/entities/chat_entity.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat List Screen - displays all chats for the current user
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _filterOption = 'all'; // all, unread

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = ref.read(authProvider).value;
        if (user != null) {
          ref.read(chatProvider.notifier).loadChats(user.uid);
        }
      }
    });
  }

  Future<String?> _getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return userDoc.data()?['displayName'] as String? ?? 'Unknown User';
      }
    } catch (e) {
      // Error getting user name
    }
    return 'Unknown User';
  }

  void _refreshChats() {
    final user = ref.read(authProvider).value;
    if (user != null) {
      ref.read(chatProvider.notifier).loadChats(user.uid);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _filterOption = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    final chatsAsync = ref.watch(chatProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(
            child: Text('Please log in to view messages'),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Messages',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                onPressed: _refreshChats,
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter chips
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
                  ],
                ),
              ),
              // Chats list
              Expanded(
                child: chatsAsync.when(
                  data: (chats) {
                    // Filter chats based on selected filter
                    final filteredChats = _filterOption == 'unread'
                        ? chats.where((chat) => chat.hasUnreadFor(user.uid)).toList()
                        : chats;

                    if (filteredChats.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filterOption == 'unread'
                                  ? 'No unread messages'
                                  : 'No messages yet',
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
                                  : 'Start a conversation with your instructor',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _refreshChats();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          return _buildChatCard(context, chat, user.uid);
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
                          'Error loading chats',
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
                          onPressed: _refreshChats,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error: ${error.toString()}',
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, ChatEntity chat, String currentUserId) {
    // Determine the other participant (not current user)
    final otherParticipantId = chat.studentId == currentUserId
        ? chat.instructorId
        : chat.studentId;

    return FutureBuilder<String?>(
      future: _getUserName(otherParticipantId),
      builder: (context, snapshot) {
        final participantName = snapshot.data ?? 'Unknown User';
        final hasUnread = chat.hasUnreadFor(currentUserId);
        final unreadCount = currentUserId == chat.studentId
            ? chat.unreadCountStudent
            : chat.unreadCountInstructor;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: hasUnread ? AppColors.buttonPrimary : AppColors.border,
              width: hasUnread ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: chat.id,
                    participantId: otherParticipantId,
                    participantName: participantName,
                  ),
                ),
              ).then((_) {
                // Refresh chats when returning from chat screen
                _refreshChats();
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.background,
                    child: Text(
                      participantName[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Chat info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                participantName,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatTimestamp(chat.lastMessageTimestamp),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat.lastMessage,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: hasUnread
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread && unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.buttonPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

