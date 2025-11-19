import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../../domain/entities/course_entity.dart';
import '../../../domain/entities/forum_topic_entity.dart';
import '../../providers/forum_topic_provider.dart';
import 'forum_topic_detail_screen.dart';
import 'widgets/topic_form_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Forum List Screen - displays all forum topics for a course
class ForumListScreen extends ConsumerStatefulWidget {
  final CourseEntity course;

  const ForumListScreen({super.key, required this.course});

  @override
  ConsumerState<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends ConsumerState<ForumListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterOption = 'all'; // all, recent, mostReplies

  @override
  void initState() {
    super.initState();
    // Load topics when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTopics();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _applySearch() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty) {
      _loadTopics();
    } else {
      ref
          .read(forumTopicProvider.notifier)
          .searchTopics(widget.course.id, query);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _filterOption = filter;
      _searchQuery = '';
      _searchController.clear();
    });

    switch (filter) {
      case 'recent':
        ref
            .read(forumTopicProvider.notifier)
            .loadRecentTopics(
              widget.course.id,
              7, // Last 7 days
            );
        break;
      case 'all':
      default:
        _loadTopics();
        break;
    }
  }

  void _loadTopics() {
    ref.read(forumTopicProvider.notifier).loadTopics(widget.course.id);
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(forumTopicProvider);

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
          'Forum',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showTopicDialog(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                MediaQuery.of(context).size.width < 600 ? 'New' : 'New Topic',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search topics...',
                    hintStyle: GoogleFonts.inter(fontSize: 14),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                  onSubmitted: (_) => _applySearch(),
                  onChanged: (_) {
                    if (_searchController.text.trim().isEmpty &&
                        _searchQuery.isNotEmpty) {
                      _applySearch();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterOption == 'all',
                      onSelected: (_) => _applyFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Recent'),
                      selected: _filterOption == 'recent',
                      onSelected: (_) => _applyFilter('recent'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Topics list
          Expanded(
            child: topicsAsync.when(
              data: (topics) {
              // Sort by most replies if filter is 'mostReplies'
              final sortedTopics = List<ForumTopicEntity>.from(topics);
              if (_filterOption == 'mostReplies') {
                sortedTopics.sort(
                  (a, b) => b.replyCount.compareTo(a.replyCount),
                );
              }

              if (sortedTopics.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No topics yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "New Topic" to start a discussion',
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
                  _loadTopics();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedTopics.length,
                  itemBuilder: (context, index) {
                    final topic = sortedTopics[index];
                    return _buildTopicCard(context, topic);
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
                      'Error loading topics',
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
                      onPressed: () => _loadTopics(),
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
  }

  Widget _buildTopicCard(BuildContext context, ForumTopicEntity topic) {
    return FutureBuilder<String?>(
      future: _getUserName(topic.authorId),
      builder: (context, snapshot) {
        final authorName = snapshot.data ?? 'Unknown User';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppColors.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForumTopicDetailScreen(
                    course: widget.course,
                    topicId: topic.id,
                  ),
                ),
              ).then((_) {
                // Refresh topics when returning from detail screen
                _loadTopics();
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    topic.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Author and date
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.background,
                        child: Text(
                          authorName[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        authorName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(topic.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Content preview
                  Text(
                    topic.content.length > 150
                        ? '${topic.content.substring(0, 150)}...'
                        : topic.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Footer with reply count and attachments
                  Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${topic.replyCount} ${topic.replyCount == 1 ? 'reply' : 'replies'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (topic.hasAttachments) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.attach_file,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.attachments.length} ${topic.attachments.length == 1 ? 'attachment' : 'attachments'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
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

  void _showTopicDialog(BuildContext context, ForumTopicEntity? topic) {
    showDialog(
      context: context,
      builder: (context) =>
          TopicFormDialog(course: widget.course, topic: topic),
    ).then((success) {
      if (mounted && success == true) {
        _loadTopics();
      }
    });
  }
}
