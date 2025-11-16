import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../common/styles/colors.dart';
import '../../../domain/entities/course_entity.dart';
import '../../../domain/entities/quiz_entity.dart';
import '../../../domain/entities/quiz_attempt_entity.dart';
import '../../../domain/entities/enrollment_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/quiz_attempt_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../utils/services/csv_export_service.dart';
import '../../../utils/helpers/file_download_helper.dart';
import 'widgets/quiz_answer_detail_dialog.dart';

/// Quiz Tracking Screen - shows quiz attempts for all students
class QuizTrackingScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final QuizEntity quiz;

  const QuizTrackingScreen({
    super.key,
    required this.course,
    required this.quiz,
  });

  @override
  ConsumerState<QuizTrackingScreen> createState() => _QuizTrackingScreenState();
}

class _QuizTrackingScreenState extends ConsumerState<QuizTrackingScreen> {
  String _filter = 'all'; // 'all', 'completed', 'not_started'
  String _sortBy = 'name'; // 'name', 'score'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enrollmentProvider.notifier).loadEnrollments(widget.course.id);
      ref.read(quizAttemptProvider.notifier).loadAttempts(widget.quiz.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentsAsync = ref.watch(enrollmentProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final attemptsAsync = ref.watch(quizAttemptProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Tracking',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.quiz.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.textPrimary),
            onPressed: () => _exportToCsv(context, ref),
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter and Sort chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Not Started', 'not_started'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Sort by: ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSortChip('Name', 'name'),
                    const SizedBox(width: 8),
                    _buildSortChip('Score', 'score'),
                  ],
                ),
              ],
            ),
          ),
          // Tracking data
          Expanded(
            child: enrollmentsAsync.when(
              data: (enrollments) {
                return studentsAsync.when(
                  data: (students) {
                    return attemptsAsync.when(
                      data: (attempts) {
                        return _buildTrackingList(
                          enrollments,
                          students,
                          attempts,
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading quiz attempts',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(quizAttemptProvider.notifier)
                                    .loadAttempts(widget.quiz.id);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading students: ${error.toString()}',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading enrollments: ${error.toString()}',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
        }
      },
      selectedColor: AppColors.buttonPrimary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.buttonPrimary,
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = value;
          });
        }
      },
      selectedColor: AppColors.buttonPrimary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.buttonPrimary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTrackingList(
    List<EnrollmentEntity> enrollments,
    List<UserEntity> students,
    List<QuizAttemptEntity> attempts,
  ) {
    // Create a map of studentId -> UserEntity
    final studentMap = <String, UserEntity>{};
    for (var student in students) {
      studentMap[student.uid] = student;
    }

    // Create a map of studentId -> all attempts (for instructor)
    final allAttemptsMap = <String, List<QuizAttemptEntity>>{};
    for (var attempt in attempts) {
      if (!allAttemptsMap.containsKey(attempt.studentId)) {
        allAttemptsMap[attempt.studentId] = [];
      }
      allAttemptsMap[attempt.studentId]!.add(attempt);
    }

    // Sort attempts by startTime descending (newest first)
    for (var studentId in allAttemptsMap.keys) {
      allAttemptsMap[studentId]!.sort(
        (a, b) => b.startTime.compareTo(a.startTime),
      );
    }

    // Create a map of studentId -> best attempt (highest score) for display
    final bestAttemptMap = <String, QuizAttemptEntity>{};
    for (var attempt in attempts) {
      if (attempt.isCompleted && attempt.score != null) {
        final existing = bestAttemptMap[attempt.studentId];
        if (existing == null || (attempt.score ?? 0) > (existing.score ?? 0)) {
          bestAttemptMap[attempt.studentId] = attempt;
        }
      }
    }

    // Get all attempt counts per student
    final attemptCounts = <String, int>{};
    for (var studentId in allAttemptsMap.keys) {
      attemptCounts[studentId] = allAttemptsMap[studentId]!.length;
    }

    // Build student tracking list
    final studentTrackingList = <_StudentQuizData>[];
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final attempt = bestAttemptMap[enrollment.studentId];
      final attemptsCount = attemptCounts[enrollment.studentId] ?? 0;
      final status = attempt != null ? 'Completed' : 'Not Started';

      studentTrackingList.add(
        _StudentQuizData(
          studentId: enrollment.studentId,
          studentName: student?.displayName ?? 'Unknown',
          attempt: attempt,
          attemptsCount: attemptsCount,
          status: status,
          allAttempts: allAttemptsMap[enrollment.studentId] ?? [],
        ),
      );
    }

    // Apply filter
    final filteredList = studentTrackingList.where((item) {
      switch (_filter) {
        case 'completed':
          return item.attempt != null;
        case 'not_started':
          return item.attempt == null;
        default:
          return true;
      }
    }).toList();

    // Apply sort
    filteredList.sort((a, b) {
      switch (_sortBy) {
        case 'score':
          final aScore = a.attempt?.score ?? 0;
          final bScore = b.attempt?.score ?? 0;
          return bScore.compareTo(aScore); // Descending
        default: // 'name'
          return a.studentName.compareTo(b.studentName);
      }
    });

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return _buildStudentQuizCard(item);
      },
    );
  }

  Widget _buildStudentQuizCard(_StudentQuizData item) {
    final hasAttempt = item.attempt != null;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final statusColor = item.status == 'Completed'
        ? Colors.green
        : AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(
            hasAttempt ? Icons.quiz : Icons.quiz_outlined,
            color: statusColor,
          ),
        ),
        title: Text(
          item.studentName,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: hasAttempt
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${item.status}',
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.attempt!.score != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Score: ${item.attempt!.score!.toStringAsFixed(1)}/${item.attempt!.maxScore.toStringAsFixed(1)} (${item.attempt!.percentage!.toStringAsFixed(1)}%)',
                      style: GoogleFonts.inter(
                        color: AppColors.buttonPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (item.attempt!.durationMinutes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Time taken: ${item.attempt!.durationMinutes} minutes',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  Text(
                    'Attempts: ${item.attemptsCount}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (item.attempt!.endTime != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Completed: ${dateFormat.format(item.attempt!.endTime!)}',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                'Not started',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
        trailing: hasAttempt
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show attempts count if multiple attempts
                  if (item.allAttempts.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.buttonPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.allAttempts.length} attempts',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonPrimary,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      // For instructor: show dialog with all attempts
                      // For student: show only best attempt
                      final user = ref.read(authProvider).value;
                      if (user?.role == UserRole.instructor &&
                          item.allAttempts.length > 1) {
                        _showAllAttemptsDialog(item);
                      } else {
                        _showAnswerDetail(item.attempt!);
                      }
                    },
                    tooltip: item.allAttempts.length > 1
                        ? 'View all attempts'
                        : 'View answers',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _showAnswerDetail(QuizAttemptEntity attempt) {
    showDialog(
      context: context,
      builder: (context) =>
          QuizAnswerDetailDialog(quiz: widget.quiz, attempt: attempt),
    );
  }

  void _showAllAttemptsDialog(_StudentQuizData item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Quiz Attempts',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.studentName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: item.allAttempts.length,
                  itemBuilder: (context, index) {
                    final attempt = item.allAttempts[index];
                    final isBest = attempt.id == item.attempt?.id;
                    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isBest
                          ? Colors.green.withValues(alpha: 0.1)
                          : null,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isBest
                                ? Colors.green
                                : AppColors.buttonPrimary.withValues(
                                    alpha: 0.2,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${attempt.attemptNumber}',
                            style: GoogleFonts.inter(
                              color: isBest
                                  ? Colors.white
                                  : AppColors.buttonPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Attempt ${attempt.attemptNumber}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Started: ${dateFormat.format(attempt.startTime)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (attempt.endTime != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Completed: ${dateFormat.format(attempt.endTime!)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (attempt.score != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Score: ${attempt.score!.toStringAsFixed(1)}/${attempt.maxScore.toStringAsFixed(1)} (${attempt.percentage!.toStringAsFixed(1)}%)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.buttonPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (attempt.durationMinutes != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Duration: ${attempt.durationMinutes} minutes',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBest)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Best',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showAnswerDetail(attempt);
                              },
                              tooltip: 'View answers',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Export quiz attempts to CSV
  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    // Get data from providers
    final enrollmentsAsync = ref.read(enrollmentProvider);
    final studentsAsync = ref.read(studentsProvider);
    final attemptsAsync = ref.read(quizAttemptProvider);

    // Check if all data is loaded
    if (enrollmentsAsync.isLoading ||
        studentsAsync.isLoading ||
        attemptsAsync.isLoading) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for data to load'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (enrollmentsAsync.hasError ||
        studentsAsync.hasError ||
        attemptsAsync.hasError) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final enrollments = enrollmentsAsync.value ?? [];
    final students = studentsAsync.value ?? [];
    final attempts = attemptsAsync.value ?? [];

    try {
      // Create student map
      final studentMap = <String, UserEntity>{};
      for (var student in students) {
        studentMap[student.uid] = student;
      }

      // Get max score from attempts (use first attempt's maxScore, or default to 100)
      final maxScore = attempts.isNotEmpty ? attempts.first.maxScore : 100.0;

      // Generate CSV content
      final csvContent = CsvExportService.exportQuizResults(
        enrollments: enrollments,
        attempts: attempts,
        studentMap: studentMap,
        maxScore: maxScore,
      );

      // Generate filename with timestamp
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final timestamp = dateFormat.format(DateTime.now());
      final filename =
          'quiz_${widget.quiz.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}_$timestamp.csv';

      // Download file
      await FileDownloadHelper.downloadCsv(
        csvContent: csvContent,
        filename: filename,
        context: context,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Helper class for student quiz data
class _StudentQuizData {
  final String studentId;
  final String studentName;
  final QuizAttemptEntity? attempt; // Best attempt
  final int attemptsCount;
  final String status;
  final List<QuizAttemptEntity> allAttempts; // All attempts for instructor

  _StudentQuizData({
    required this.studentId,
    required this.studentName,
    this.attempt,
    required this.attemptsCount,
    required this.status,
    required this.allAttempts,
  });
}
