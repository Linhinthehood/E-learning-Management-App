import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/forum_reply_entity.dart';
import '../../../providers/forum_reply_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Reply Widget - displays a forum reply with edit/delete options
class ReplyWidget extends ConsumerStatefulWidget {
  final ForumReplyEntity reply;
  final String topicId;
  final int depth; // Depth in the reply tree (0 = top level)
  final VoidCallback onReplyUpdated;

  const ReplyWidget({
    super.key,
    required this.reply,
    required this.topicId,
    this.depth = 0,
    required this.onReplyUpdated,
  });

  @override
  ConsumerState<ReplyWidget> createState() => _ReplyWidgetState();
}

class _ReplyWidgetState extends ConsumerState<ReplyWidget> {
  final TextEditingController _editController = TextEditingController();
  bool _isEditing = false;
  bool _showReplyInput = false;

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

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.reply.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editController.clear();
    });
  }

  void _saveEdit() async {
    final content = _editController.text.trim();
    if (content.isEmpty) return;

    try {
      final updatedReply = ForumReplyEntity(
        id: widget.reply.id,
        topicId: widget.reply.topicId,
        content: content,
        authorId: widget.reply.authorId,
        createdAt: widget.reply.createdAt,
        replyToId: widget.reply.replyToId,
      );

      await ref.read(forumReplyProvider.notifier).updateReply(updatedReply);
      widget.onReplyUpdated();
      setState(() {
        _isEditing = false;
        _editController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating reply: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteReply() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Reply',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this reply?',
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
                    .read(forumReplyProvider.notifier)
                    .deleteReply(widget.reply.id);
                widget.onReplyUpdated();
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

  void _sendReply(String content) {
    final user = ref.read(authProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to reply'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reply = ForumReplyEntity(
      id: '',
      topicId: widget.topicId,
      content: content,
      authorId: user.uid,
      createdAt: DateTime.now(),
      replyToId: widget.reply.id, // This is a reply to this reply
    );

    ref.read(forumReplyProvider.notifier).createReply(reply).then((_) {
      widget.onReplyUpdated();
      setState(() {
        _showReplyInput = false;
      });
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reply: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    final user = userAsync.value;
    final isAuthor = user?.uid == widget.reply.authorId;

    return FutureBuilder<String?>(
      future: _getUserName(widget.reply.authorId),
      builder: (context, snapshot) {
        final authorName = snapshot.data ?? 'Unknown User';

        return Padding(
          padding: EdgeInsets.only(left: widget.depth * 24.0, bottom: 16),
          child: Card(
            color: AppColors.cardBackground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author and actions
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.background,
                        child: Text(
                          authorName[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _formatDate(widget.reply.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isAuthor)
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert, size: 16),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () => _startEditing(),
                                );
                              },
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () => _deleteReply(),
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Reply content
                  if (_isEditing)
                    Column(
                      children: [
                        TextField(
                          controller: _editController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                          maxLines: 4,
                          autofocus: true,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _cancelEditing,
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _saveEdit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                'Save',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Text(
                      widget.reply.content,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Reply button
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showReplyInput = !_showReplyInput;
                      });
                    },
                    icon: const Icon(Icons.reply, size: 16),
                    label: Text(
                      'Reply',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  // Reply input
                  if (_showReplyInput)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _ReplyInputField(
                        onSend: _sendReply,
                        onCancel: () {
                          setState(() {
                            _showReplyInput = false;
                          });
                        },
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
}

/// Reply input field widget
class _ReplyInputField extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onCancel;

  const _ReplyInputField({
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<_ReplyInputField> createState() => _ReplyInputFieldState();
}

class _ReplyInputFieldState extends State<_ReplyInputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      widget.onSend(content);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Write a reply...',
              hintStyle: GoogleFonts.inter(fontSize: 12),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 12),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _send,
          icon: const Icon(Icons.send, size: 18),
          color: AppColors.buttonPrimary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.close, size: 18),
          color: AppColors.textSecondary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

