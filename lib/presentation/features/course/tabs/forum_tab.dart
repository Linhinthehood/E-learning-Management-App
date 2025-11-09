import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../providers/forum_topic_provider.dart';
import '../../forum/forum_list_screen.dart';

/// Forum tab - displays forum topics for a course
class ForumTab extends ConsumerStatefulWidget {
  final CourseEntity course;

  const ForumTab({super.key, required this.course});

  @override
  ConsumerState<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends ConsumerState<ForumTab> {
  @override
  void initState() {
    super.initState();
    // Load forum topics when tab is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(forumTopicProvider.notifier).loadTopics(widget.course.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ForumListScreen(course: widget.course);
  }
}

