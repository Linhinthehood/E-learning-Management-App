import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/quiz_entity.dart';
import '../../../../domain/entities/quiz_attempt_entity.dart';
import '../../../providers/quiz_provider.dart';
import '../../../providers/quiz_attempt_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/quiz_form_dialog.dart';
import '../quiz_taking_screen.dart';
import '../../tracking/quiz_tracking_screen.dart';

/// Quizzes tab - displays and manages quizzes
class QuizzesTab extends ConsumerStatefulWidget {
  final CourseEntity course;
  final bool isReadOnly;

  const QuizzesTab({super.key, required this.course, this.isReadOnly = false});

  @override
  ConsumerState<QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends ConsumerState<QuizzesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'Close Date (Nearest First)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(quizProvider.notifier).loadQuizzes(widget.course.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QuizEntity> _applyFiltersAndSort(List<QuizEntity> quizzes) {
    var filtered = quizzes.where((quiz) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            quiz.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            quiz.description.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }

      // Status filter
      if (_filterStatus != 'All') {
        switch (_filterStatus) {
          case 'Open':
            if (!quiz.isOpen) return false;
            break;
          case 'Closed':
            if (!quiz.isClosed) return false;
            break;
          case 'Upcoming':
            if (!quiz.isUpcoming) return false;
            break;
        }
      }

      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Close Date (Nearest First)':
        filtered.sort((a, b) => a.timeClose.compareTo(b.timeClose));
        break;
      case 'Close Date (Furthest First)':
        filtered.sort((a, b) => b.timeClose.compareTo(a.timeClose));
        break;
      case 'Title (A-Z)':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Title (Z-A)':
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(quizProvider);

    return quizzesAsync.when(
      data: (quizzes) {
        final filteredQuizzes = _applyFiltersAndSort(quizzes);

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quizzes',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showQuizDialog(context, ref, null),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add Quiz',
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

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search quizzes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
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
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter and Sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    // ignore: deprecated_member_use
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _filterStatus,
                      decoration: InputDecoration(
                        labelText: 'Filter by Status',
                        prefixIcon: const Icon(Icons.filter_list, size: 20),
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
                      ),
                      items: ['All', 'Open', 'Closed', 'Upcoming'].map((
                        status,
                      ) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _filterStatus = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // ignore: deprecated_member_use
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _sortBy,
                      decoration: InputDecoration(
                        labelText: 'Sort by',
                        prefixIcon: const Icon(Icons.sort, size: 20),
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
                      ),
                      items:
                          [
                            'Close Date (Nearest First)',
                            'Close Date (Furthest First)',
                            'Title (A-Z)',
                            'Title (Z-A)',
                          ].map((sortOption) {
                            return DropdownMenuItem(
                              value: sortOption,
                              child: Text(
                                sortOption,
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filteredQuizzes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _filterStatus != 'All'
                                ? 'No quizzes match your filters'
                                : 'No quizzes yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _filterStatus != 'All') ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _filterStatus = 'All';
                                });
                              },
                              child: Text(
                                'Clear filters',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.buttonPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filteredQuizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = filteredQuizzes[index];
                        return _buildQuizCard(context, ref, quiz);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading quizzes'),
            ElevatedButton(
              onPressed: () {
                ref.read(quizProvider.notifier).loadQuizzes(widget.course.id);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, WidgetRef ref, QuizEntity quiz) {
    final userAsync = ref.read(authProvider);
    final isAuthor = userAsync.value?.uid == widget.course.instructorId;
    final currentUserId = userAsync.value?.uid;

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
                        quiz.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            quiz.isOpen
                                ? Icons.check_circle
                                : quiz.isClosed
                                ? Icons.cancel
                                : Icons.schedule,
                            size: 16,
                            color: quiz.isOpen
                                ? Colors.green
                                : quiz.isClosed
                                ? Colors.red
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quiz.isOpen
                                ? 'Open'
                                : quiz.isClosed
                                ? 'Closed'
                                : 'Upcoming',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: quiz.isOpen
                                  ? Colors.green
                                  : quiz.isClosed
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Closes: ${_formatDateTime(quiz.timeClose)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                              _showQuizDialog(navigatorContext, ref, quiz);
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
                                  builder: (context) => QuizTrackingScreen(
                                    course: widget.course,
                                    quiz: quiz,
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
                              _deleteQuiz(navigatorContext, ref, quiz);
                            }
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              quiz.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Details
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (quiz.hasTimeLimit)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${quiz.durationMinutes} minutes',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_off,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'No time limit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quiz.hasUnlimitedAttempts
                          ? 'Unlimited attempts'
                          : '${quiz.numAttempts} attempt(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${quiz.structure.totalQuestions} question(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (quiz.shuffleQuestions || quiz.shuffleAnswers)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shuffle, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        quiz.shuffleQuestions && quiz.shuffleAnswers
                            ? 'Shuffle questions & answers'
                            : quiz.shuffleQuestions
                            ? 'Shuffle questions'
                            : 'Shuffle answers',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                if (!quiz.isForAllGroups)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
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
            ),

            // Student quiz attempt section
            if (!isAuthor && currentUserId != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              FutureBuilder<QuizAttemptEntity?>(
                future: ref
                    .read(quizAttemptProvider.notifier)
                    .getBestAttempt(quiz.id, currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final bestAttempt = snapshot.data;

                  return FutureBuilder<int>(
                    future: ref
                        .read(quizAttemptProvider.notifier)
                        .countStudentAttempts(quiz.id, currentUserId),
                    builder: (context, countSnapshot) {
                      final attemptCount = countSnapshot.data ?? 0;
                      final canTake =
                          quiz.hasUnlimitedAttempts ||
                          attemptCount < quiz.numAttempts;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Attempt status (showing best score)
                          _buildAttemptStatus(bestAttempt, attemptCount, quiz),
                          // Show attempts count if multiple attempts
                          if (attemptCount > 1) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.buttonPrimary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 16,
                                    color: AppColors.buttonPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total attempts: $attemptCount',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.buttonPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(Best score shown above)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Take quiz button
                          if (canTake && quiz.isOpen)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _startQuiz(
                                  context,
                                  ref,
                                  quiz,
                                  currentUserId,
                                ),
                                icon: const Icon(Icons.play_arrow, size: 20),
                                label: Text(
                                  attemptCount == 0
                                      ? 'Start Quiz'
                                      : bestAttempt?.isInProgress == true
                                      ? 'Continue Quiz'
                                      : 'Start Attempt ${attemptCount + 1}',
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
                            )
                          else if (!canTake)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Maximum attempts reached',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showQuizDialog(BuildContext context, WidgetRef ref, QuizEntity? quiz) {
    showDialog(
      context: context,
      builder: (context) => QuizFormDialog(course: widget.course, quiz: quiz),
    ).then((success) {
      if (mounted && success == true) {
        ref.read(quizProvider.notifier).loadQuizzes(widget.course.id);
      }
    });
  }

  void _deleteQuiz(BuildContext context, WidgetRef ref, QuizEntity quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Quiz',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${quiz.title}"? This action cannot be undone.',
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
                await ref.read(quizProvider.notifier).deleteQuiz(quiz.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${quiz.title} deleted successfully'),
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

  Widget _buildAttemptStatus(
    QuizAttemptEntity? attempt,
    int attemptCount,
    QuizEntity quiz,
  ) {
    if (attempt == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            const Icon(Icons.quiz, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              'Not attempted yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (attempt.isGraded) {
      statusColor = Colors.blue;
      statusIcon = Icons.grading;
      final percentage = attempt.percentage ?? 0;
      statusText =
          'Graded: ${attempt.score?.toStringAsFixed(1)}/${attempt.maxScore} (${percentage.toStringAsFixed(1)}%)';
    } else if (attempt.isInProgress) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Quiz in progress (Attempt $attemptCount)';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      final percentage = attempt.percentage ?? 0;
      statusText =
          'Completed: ${attempt.score?.toStringAsFixed(1)}/${attempt.maxScore} (${percentage.toStringAsFixed(1)}%)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (attempt.feedback != null && attempt.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Feedback:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              attempt.feedback!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (attempt.endTime != null) ...[
            const SizedBox(height: 8),
            Text(
              'Submitted: ${_formatDateTime(attempt.endTime!)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startQuiz(
    BuildContext context,
    WidgetRef ref,
    QuizEntity quiz,
    String studentId,
  ) async {
    // Capture context before async
    final navigatorContext = context;

    // Check if there's an in-progress attempt
    final inProgressAttempt = await ref
        .read(quizAttemptProvider.notifier)
        .getInProgressAttempt(quiz.id, studentId);

    if (!mounted || !navigatorContext.mounted) return;

    // Navigate to quiz taking screen
    final result = await Navigator.of(navigatorContext).push(
      MaterialPageRoute(
        builder: (context) =>
            QuizTakingScreen(quiz: quiz, existingAttempt: inProgressAttempt),
      ),
    );

    // Refresh the quiz list if quiz was completed
    if (result == true && mounted) {
      ref.read(quizProvider.notifier).loadQuizzes(widget.course.id);
    }
  }
}
