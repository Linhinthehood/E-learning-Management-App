import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/announcement_entity.dart';
import '../../../../domain/entities/comment_entity.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/comment_provider.dart';
import '../../../providers/view_tracking_provider.dart';
import '../widgets/announcement_form_dialog.dart';
import '../../tracking/announcement_tracking_screen.dart';

/// Announcements tab - displays and manages announcements
class AnnouncementsTab extends ConsumerStatefulWidget {
  final CourseEntity course;

  const AnnouncementsTab({super.key, required this.course});

  @override
  ConsumerState<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends ConsumerState<AnnouncementsTab> {
  @override
  void initState() {
    super.initState();
    // Load announcements when tab is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(announcementProvider.notifier)
            .loadAnnouncements(widget.course.id);
        // Load groups for scope selection (if needed later)
        ref.read(groupProvider.notifier).loadGroups(widget.course.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementProvider);
    final groupsAsync = ref.watch(groupProvider);

    return announcementsAsync.when(
      data: (announcements) {
        return Column(
          children: [
            // Header with Add button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Announcements',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showAnnouncementDialog(context, ref, null),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add Announcement',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Announcements list
            Expanded(
              child: announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.announcement_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No announcements yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Add Announcement" to create your first announcement',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        return _buildAnnouncementCard(
                          context,
                          ref,
                          announcement,
                          groupsAsync,
                        );
                      },
                    ),
            ),
          ],
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
              'Error loading announcements',
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
              onPressed: () {
                ref
                    .read(announcementProvider.notifier)
                    .loadAnnouncements(widget.course.id);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    WidgetRef ref,
    AnnouncementEntity announcement,
    AsyncValue<List<dynamic>> groupsAsync,
  ) {
    final userAsync = ref.read(authProvider);
    final user = userAsync.value;
    final isAuthor = user?.uid == announcement.authorId;

    // Track view for students (not for instructors/authors)
    if (user != null && !isAuthor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(viewTrackingByContentProvider(
              (contentId: announcement.id, contentType: 'announcement'),
            ).notifier)
            .trackView();
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(announcement.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAuthor)
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                        onTap: () {
                          final navigatorContext = context;
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && navigatorContext.mounted) {
                              _showAnnouncementDialog(
                                navigatorContext,
                                ref,
                                announcement,
                              );
                            }
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.analytics, size: 20),
                            SizedBox(width: 8),
                            Text('View Tracking'),
                          ],
                        ),
                        onTap: () {
                          final navigatorContext = context;
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && navigatorContext.mounted) {
                              Navigator.of(navigatorContext).push(
                                MaterialPageRoute(
                                  builder: (context) => AnnouncementTrackingScreen(
                                    course: widget.course,
                                    announcement: announcement,
                                  ),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () {
                          final navigatorContext = context;
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && navigatorContext.mounted) {
                              _deleteAnnouncement(
                                navigatorContext,
                                ref,
                                announcement,
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              announcement.content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),

            // Attachments
            if (announcement.hasAttachments) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: announcement.attachments.map((attachment) {
                  return Chip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: Text(
                      attachment.split('/').last,
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    backgroundColor: AppColors.background,
                  );
                }).toList(),
              ),
            ],

            // Scope info
            if (!announcement.isForAllGroups) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Scoped to specific groups',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            // Comments section
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 12),
            _buildCommentsSection(context, ref, announcement),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(
    BuildContext context,
    WidgetRef ref,
    AnnouncementEntity announcement,
  ) {
    final commentsAsync = ref.watch(commentProvider(announcement.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments header
        commentsAsync.when(
          data: (comments) => Text(
            'Comments (${comments.length})',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          loading: () => Text(
            'Comments',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          error: (_, __) => Text(
            'Comments',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Comments list
        commentsAsync.when(
          data: (comments) => comments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No comments yet',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : Column(
                  children: comments
                      .map((comment) => _buildCommentItem(
                            context,
                            ref,
                            comment,
                            announcement.id,
                          ))
                      .toList(),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Error loading comments',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        ),

        // Add comment input
        const SizedBox(height: 12),
        _buildCommentInput(context, ref, announcement.id),
      ],
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    WidgetRef ref,
    CommentEntity comment,
    String announcementId,
  ) {
    final userAsync = ref.read(authProvider);
    final isAuthor = userAsync.value?.uid == comment.authorId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.background,
            child: Text(
              comment.authorName[0].toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Comment content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author and time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (isAuthor) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _deleteComment(
                            context,
                            ref,
                            comment.id,
                            announcementId,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Comment text
                  Text(
                    comment.content,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (comment.wasEdited) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Edited',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    WidgetRef ref,
    String announcementId,
  ) {
    final TextEditingController commentController = TextEditingController();

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: GoogleFonts.inter(fontSize: 12),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 12),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _addComment(context, ref, announcementId, value.trim());
                commentController.clear();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            final text = commentController.text.trim();
            if (text.isNotEmpty) {
              _addComment(context, ref, announcementId, text);
              commentController.clear();
            }
          },
          icon: const Icon(Icons.send, size: 20),
          color: AppColors.buttonPrimary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Future<void> _addComment(
    BuildContext context,
    WidgetRef ref,
    String announcementId,
    String content,
  ) async {
    try {
      await ref.read(commentProvider(announcementId).notifier).addComment(content);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(
    BuildContext context,
    WidgetRef ref,
    String commentId,
    String announcementId,
  ) async {
    try {
      await ref.read(commentProvider(announcementId).notifier).deleteComment(commentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
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

  void _showAnnouncementDialog(
    BuildContext context,
    WidgetRef ref,
    AnnouncementEntity? announcement,
  ) {
    showDialog(
      context: context,
      builder: (context) => AnnouncementFormDialog(
        course: widget.course,
        announcement: announcement,
      ),
    ).then((success) {
      if (mounted && success == true) {
        ref
            .read(announcementProvider.notifier)
            .loadAnnouncements(widget.course.id);
      }
    });
  }

  void _deleteAnnouncement(
    BuildContext context,
    WidgetRef ref,
    AnnouncementEntity announcement,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Announcement',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${announcement.title}"? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(announcementProvider.notifier)
                    .deleteAnnouncement(announcement.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${announcement.title} deleted successfully',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
