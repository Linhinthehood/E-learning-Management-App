import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/assignment_entity.dart';
import '../../../../domain/entities/assignment_submission_entity.dart';
import '../../../providers/assignment_submission_provider.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/assignment_submission_dialog.dart';
import '../../../../services/file_download_service.dart';

/// Assignment Detail Screen for Students - View submission details and edit files
class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final AssignmentEntity assignment;

  const AssignmentDetailScreen({
    super.key,
    required this.course,
    required this.assignment,
  });

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.read(authProvider);
    final currentUserId = userAsync.value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.assignment.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: currentUserId == null
          ? const Center(child: Text('Please log in'))
          : FutureBuilder<AssignmentSubmissionEntity?>(
              future: ref
                  .read(assignmentSubmissionProvider.notifier)
                  .getLatestSubmission(widget.assignment.id, currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final latestSubmission = snapshot.data;
                final attemptCount = latestSubmission?.attemptNumber ?? 0;
                final canSubmit =
                    widget.assignment.hasUnlimitedAttempts ||
                    attemptCount < widget.assignment.maxAttempts;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assignment info
                      Card(
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
                              Text(
                                widget.assignment.title,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.assignment.description,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.assignment.isOpen
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : widget.assignment.isClosed
                                              ? Colors.red.withValues(alpha: 0.1)
                                              : Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.assignment.isOpen
                                          ? 'Open'
                                          : widget.assignment.isClosed
                                              ? 'Closed'
                                              : 'Upcoming',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: widget.assignment.isOpen
                                            ? Colors.green
                                            : widget.assignment.isClosed
                                                ? Colors.red
                                                : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Deadline: ${_formatDateTime(widget.assignment.deadline)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.assignment.lateDeadline != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Late Deadline: ${_formatDateTime(widget.assignment.lateDeadline!)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Submission section
                      Text(
                        'My Submission',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (latestSubmission == null)
                        Card(
                          color: AppColors.cardBackground,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pending_actions,
                                  size: 48,
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Not submitted yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (canSubmit && widget.assignment.isOpen && !widget.assignment.isClosed) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showSubmissionDialog(
                                        context,
                                        ref,
                                        widget.assignment,
                                        1,
                                      ),
                                      icon: const Icon(Icons.upload_file, size: 18),
                                      label: const Text('Submit Assignment'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.buttonPrimary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else
                        Card(
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
                                // Status
                                Row(
                                  children: [
                                    Icon(
                                      latestSubmission.status == SubmissionStatus.graded
                                          ? Icons.grading
                                          : latestSubmission.status == SubmissionStatus.late
                                              ? Icons.schedule
                                              : Icons.check_circle,
                                      color: latestSubmission.status == SubmissionStatus.graded
                                          ? Colors.blue
                                          : latestSubmission.status == SubmissionStatus.late
                                              ? Colors.orange
                                              : Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      latestSubmission.status == SubmissionStatus.graded
                                          ? 'Graded'
                                          : latestSubmission.status == SubmissionStatus.late
                                              ? 'Submitted Late'
                                              : 'Submitted',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: latestSubmission.status == SubmissionStatus.graded
                                            ? Colors.blue
                                            : latestSubmission.status == SubmissionStatus.late
                                                ? Colors.orange
                                                : Colors.green,
                                      ),
                                    ),
                                    if (latestSubmission.grade != null) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        'Grade: ${latestSubmission.grade!.toStringAsFixed(1)} points',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Submission time
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Submitted: ${_formatDateTime(latestSubmission.submissionTime)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Attempt ${latestSubmission.attemptNumber}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),

                                // Feedback
                                if (latestSubmission.feedback != null && latestSubmission.feedback!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Feedback:',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          latestSubmission.feedback!,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Submitted files
                                if (latestSubmission.files.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Submitted Files (${latestSubmission.files.length})',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...latestSubmission.files.map((fileUrl) {
                                    final fileName = fileUrl.split('/').last;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.attach_file, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              fileName,
                                              style: GoogleFonts.inter(fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.open_in_new, size: 18),
                                            onPressed: () => _openFile(context, fileUrl),
                                            tooltip: 'Open file',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.download, size: 18),
                                            onPressed: () => _downloadFile(context, fileUrl, fileName),
                                            tooltip: 'Download file',
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                // Edit submission button
                                if (canSubmit && widget.assignment.isOpen && !widget.assignment.isClosed) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showSubmissionDialog(
                                        context,
                                        ref,
                                        widget.assignment,
                                        latestSubmission.attemptNumber + 1,
                                      ),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: Text(
                                        'Edit Submission (Attempt ${latestSubmission.attemptNumber + 1})',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.buttonPrimary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
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
              },
            ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSubmissionDialog(
    BuildContext context,
    WidgetRef ref,
    AssignmentEntity assignment,
    int attemptNumber,
  ) {
    showDialog(
      context: context,
      builder: (context) => AssignmentSubmissionDialog(
        assignment: assignment,
        attemptNumber: attemptNumber,
      ),
    ).then((success) {
      if (mounted && success == true) {
        // Refresh the assignment list in parent screen
        ref.read(assignmentProvider.notifier).loadAssignments(widget.assignment.courseId);
        setState(() {}); // Refresh UI
      }
    });
  }

  Future<void> _openFile(BuildContext context, String fileUrl) async {
    final downloadService = FileDownloadService();

    try {
      await downloadService.openFile(fileUrl: fileUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(
    BuildContext context,
    String fileUrl,
    String fileName,
  ) async {
    final downloadService = FileDownloadService();

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Downloading $fileName...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await downloadService.downloadFile(fileUrl: fileUrl, fileName: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.contains('untrusted')
                  ? 'Cannot download: Cloudinary account needs verification. Use "Open" to view file.'
                  : 'Failed to download file: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

