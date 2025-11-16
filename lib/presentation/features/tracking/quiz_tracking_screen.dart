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

    // Create a map of studentId -> best attempt (highest score)
    final attemptMap = <String, QuizAttemptEntity>{};
    for (var attempt in attempts) {
      if (attempt.isCompleted) {
        final existing = attemptMap[attempt.studentId];
        if (existing == null || (attempt.score ?? 0) > (existing.score ?? 0)) {
          attemptMap[attempt.studentId] = attempt;
        }
      }
    }

    // Get all attempt counts per student
    final attemptCounts = <String, int>{};
    for (var attempt in attempts) {
      attemptCounts[attempt.studentId] =
          (attemptCounts[attempt.studentId] ?? 0) + 1;
    }

    // Build student tracking list
    final studentTrackingList = <_StudentQuizData>[];
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final attempt = attemptMap[enrollment.studentId];
      final attemptsCount = attemptCounts[enrollment.studentId] ?? 0;
      final status = attempt != null ? 'Completed' : 'Not Started';

      studentTrackingList.add(
        _StudentQuizData(
          studentId: enrollment.studentId,
          studentName: student?.displayName ?? 'Unknown',
          attempt: attempt,
          attemptsCount: attemptsCount,
          status: status,
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
            ? IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  _showAnswerDetail(item.attempt!);
                },
                tooltip: 'View answers',
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
  final QuizAttemptEntity? attempt;
  final int attemptsCount;
  final String status;

  _StudentQuizData({
    required this.studentId,
    required this.studentName,
    this.attempt,
    required this.attemptsCount,
    required this.status,
  });
}
