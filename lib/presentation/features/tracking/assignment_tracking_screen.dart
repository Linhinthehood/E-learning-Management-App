import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../common/styles/colors.dart';
import '../../../domain/entities/course_entity.dart';
import '../../../domain/entities/assignment_entity.dart';
import '../../../domain/entities/assignment_submission_entity.dart';
import '../../../domain/entities/enrollment_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/assignment_submission_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../../utils/services/csv_export_service.dart';
import '../../../utils/helpers/file_download_helper.dart';

/// Assignment Tracking Screen - shows submission status for all students
class AssignmentTrackingScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final AssignmentEntity assignment;

  const AssignmentTrackingScreen({
    super.key,
    required this.course,
    required this.assignment,
  });

  @override
  ConsumerState<AssignmentTrackingScreen> createState() =>
      _AssignmentTrackingScreenState();
}

class _AssignmentTrackingScreenState
    extends ConsumerState<AssignmentTrackingScreen> {
  String _filter = 'all'; // 'all', 'submitted', 'not_submitted', 'late'
  String _sortBy = 'name'; // 'name', 'grade', 'submission_time'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enrollmentProvider.notifier).loadEnrollments(widget.course.id);
      ref
          .read(assignmentSubmissionProvider.notifier)
          .loadSubmissions(widget.assignment.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentsAsync = ref.watch(enrollmentProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final submissionsAsync = ref.watch(assignmentSubmissionProvider);

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
              'Assignment Tracking',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.assignment.title,
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
                    _buildFilterChip('Submitted', 'submitted'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Not Submitted', 'not_submitted'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Late', 'late'),
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
                    _buildSortChip('Grade', 'grade'),
                    const SizedBox(width: 8),
                    _buildSortChip('Time', 'submission_time'),
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
                    return submissionsAsync.when(
                      data: (submissions) {
                        return _buildTrackingList(
                          enrollments,
                          students,
                          submissions,
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
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
                              'Error loading submissions',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(assignmentSubmissionProvider.notifier)
                                    .loadSubmissions(widget.assignment.id);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading students: ${error.toString()}',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
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
    List<AssignmentSubmissionEntity> submissions,
  ) {
    // Create a map of studentId -> UserEntity
    final studentMap = <String, UserEntity>{};
    for (var student in students) {
      studentMap[student.uid] = student;
    }

    // Create a map of studentId -> latest submission
    final submissionMap = <String, AssignmentSubmissionEntity>{};
    for (var submission in submissions) {
      final existing = submissionMap[submission.studentId];
      if (existing == null ||
          submission.attemptNumber > existing.attemptNumber) {
        submissionMap[submission.studentId] = submission;
      }
    }

    // Build student tracking list
    final studentTrackingList = <_StudentSubmissionData>[];
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final submission = submissionMap[enrollment.studentId];
      
      // Determine status
      String status;
      if (submission == null) {
        status = 'Not Submitted';
      } else if (submission.isLate(widget.assignment.deadline)) {
        status = 'Late';
      } else {
        status = 'Submitted';
      }

      studentTrackingList.add(_StudentSubmissionData(
        studentId: enrollment.studentId,
        studentName: student?.displayName ?? 'Unknown',
        submission: submission,
        status: status,
      ));
    }

    // Apply filter
    final filteredList = studentTrackingList.where((item) {
      switch (_filter) {
        case 'submitted':
          return item.submission != null &&
              !item.submission!.isLate(widget.assignment.deadline);
        case 'not_submitted':
          return item.submission == null;
        case 'late':
          return item.submission != null &&
              item.submission!.isLate(widget.assignment.deadline);
        default:
          return true;
      }
    }).toList();

    // Apply sort
    filteredList.sort((a, b) {
      switch (_sortBy) {
        case 'grade':
          final aGrade = a.submission?.grade ?? 0;
          final bGrade = b.submission?.grade ?? 0;
          return bGrade.compareTo(aGrade); // Descending
        case 'submission_time':
          if (a.submission == null && b.submission == null) return 0;
          if (a.submission == null) return 1;
          if (b.submission == null) return -1;
          return b.submission!.submissionTime
              .compareTo(a.submission!.submissionTime); // Descending
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
              Icons.assignment_outlined,
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
        return _buildStudentSubmissionCard(item);
      },
    );
  }

  Widget _buildStudentSubmissionCard(_StudentSubmissionData item) {
    final hasSubmission = item.submission != null;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final statusColor = item.status == 'Submitted'
        ? Colors.green
        : item.status == 'Late'
            ? Colors.orange
            : AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(
            hasSubmission ? Icons.assignment_turned_in : Icons.assignment_outlined,
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
        subtitle: hasSubmission
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
                  Text(
                    'Attempt: ${item.submission!.attemptNumber}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Submitted: ${dateFormat.format(item.submission!.submissionTime)}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (item.submission!.grade != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Grade: ${item.submission!.grade!.toStringAsFixed(1)}',
                      style: GoogleFonts.inter(
                        color: AppColors.buttonPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (item.submission!.files.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.submission!.files.length} file(s)',
                      style: GoogleFonts.inter(
                        color: AppColors.buttonPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                'Not submitted',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
        trailing: hasSubmission && item.submission!.files.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  _showFilesDialog(item.submission!.files);
                },
                tooltip: 'View files',
              )
            : null,
      ),
    );
  }

  void _showFilesDialog(List<String> fileUrls) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submitted Files'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: fileUrls.length,
            itemBuilder: (context, index) {
              final url = fileUrls[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(
                  'File ${index + 1}',
                  style: GoogleFonts.inter(),
                ),
                subtitle: Text(
                  url,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // TODO: Implement file download/open functionality
                  // For web: window.open(url)
                  // For mobile: Use url_launcher package
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File URL: $url'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Export assignment submissions to CSV
  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    // Get data from providers
    final enrollmentsAsync = ref.read(enrollmentProvider);
    final studentsAsync = ref.read(studentsProvider);
    final submissionsAsync = ref.read(assignmentSubmissionProvider);

    // Check if all data is loaded
    if (enrollmentsAsync.isLoading || 
        studentsAsync.isLoading || 
        submissionsAsync.isLoading) {
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
        submissionsAsync.hasError) {
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
    final submissions = submissionsAsync.value ?? [];

    if (submissions.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No submissions to export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Create student map
      final studentMap = <String, UserEntity>{};
      for (var student in students) {
        studentMap[student.uid] = student;
      }

      // Generate CSV content
      final csvContent = CsvExportService.exportAssignmentSubmissions(
        enrollments: enrollments,
        submissions: submissions,
        studentMap: studentMap,
        assignment: widget.assignment,
      );

      // Generate filename with timestamp
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final timestamp = dateFormat.format(DateTime.now());
      final filename = 'assignment_${widget.assignment.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}_$timestamp.csv';

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

/// Helper class for student submission data
class _StudentSubmissionData {
  final String studentId;
  final String studentName;
  final AssignmentSubmissionEntity? submission;
  final String status;

  _StudentSubmissionData({
    required this.studentId,
    required this.studentName,
    this.submission,
    required this.status,
  });
}

