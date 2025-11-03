import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/assignment_entity.dart';
import '../../../../domain/entities/assignment_submission_entity.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/assignment_submission_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/assignment_form_dialog.dart';
import '../widgets/assignment_submission_dialog.dart';

/// Assignments tab - displays and manages assignments
class AssignmentsTab extends ConsumerStatefulWidget {
  final CourseEntity course;

  const AssignmentsTab({super.key, required this.course});

  @override
  ConsumerState<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends ConsumerState<AssignmentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'Deadline (Nearest First)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(assignmentProvider.notifier).loadAssignments(widget.course.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AssignmentEntity> _applyFiltersAndSort(List<AssignmentEntity> assignments) {
    var filtered = assignments.where((assignment) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = assignment.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            assignment.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }

      // Status filter
      if (_filterStatus != 'All') {
        switch (_filterStatus) {
          case 'Open':
            if (!assignment.isOpen) return false;
            break;
          case 'Closed':
            if (!assignment.isClosed) return false;
            break;
          case 'Upcoming':
            if (!assignment.isUpcoming) return false;
            break;
        }
      }

      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Deadline (Nearest First)':
        filtered.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'Deadline (Furthest First)':
        filtered.sort((a, b) => b.deadline.compareTo(a.deadline));
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
    final assignmentsAsync = ref.watch(assignmentProvider);

    return assignmentsAsync.when(
      data: (assignments) {
        final filteredAssignments = _applyFiltersAndSort(assignments);

        return Column(
          children: [
            // Header with title and Add button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assignments',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAssignmentDialog(context, ref, null),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add Assignment',
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
                  hintText: 'Search assignments...',
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

            // Filter and Sort controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Filter dropdown
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
                      items: [
                        'All',
                        'Open',
                        'Closed',
                        'Upcoming',
                      ].map((status) {
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

                  // Sort dropdown
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
                      items: [
                        'Deadline (Nearest First)',
                        'Deadline (Furthest First)',
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
              child: filteredAssignments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _filterStatus != 'All'
                                ? 'No assignments match your filters'
                                : 'No assignments yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _filterStatus != 'All') ...[
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
                      itemCount: filteredAssignments.length,
                      itemBuilder: (context, index) {
                        final assignment = filteredAssignments[index];
                        return _buildAssignmentCard(context, ref, assignment);
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
            Text('Error loading assignments'),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(assignmentProvider.notifier)
                    .loadAssignments(widget.course.id);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    WidgetRef ref,
    AssignmentEntity assignment,
  ) {
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
                        assignment.title,
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
                            assignment.isOpen
                                ? Icons.check_circle
                                : assignment.isClosed
                                ? Icons.cancel
                                : Icons.schedule,
                            size: 16,
                            color: assignment.isOpen
                                ? Colors.green
                                : assignment.isClosed
                                ? Colors.red
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            assignment.isOpen
                                ? 'Open'
                                : assignment.isClosed
                                ? 'Closed'
                                : 'Upcoming',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: assignment.isOpen
                                  ? Colors.green
                                  : assignment.isClosed
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Deadline: ${_formatDateTime(assignment.deadline)}',
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
                              _showAssignmentDialog(
                                navigatorContext,
                                ref,
                                assignment,
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
                              _deleteAssignment(
                                navigatorContext,
                                ref,
                                assignment,
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

            // Description
            Text(
              assignment.description,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Max ${assignment.maxFileSizeMB}MB',
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
                      assignment.hasUnlimitedAttempts
                          ? 'Unlimited attempts'
                          : '${assignment.maxAttempts} attempt(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (assignment.allowsLateSubmission)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Late submission allowed',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                if (!assignment.isForAllGroups)
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
            if (assignment.allowedFileFormats.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assignment.allowedFileFormats.map((format) {
                  return Chip(
                    avatar: const Icon(Icons.insert_drive_file, size: 16),
                    label: Text(
                      format.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    backgroundColor: AppColors.background,
                  );
                }).toList(),
              ),
            ],

            // Student submission section
            if (!isAuthor && currentUserId != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              FutureBuilder<AssignmentSubmissionEntity?>(
                future: ref
                    .read(assignmentSubmissionProvider.notifier)
                    .getLatestSubmission(assignment.id, currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final latestSubmission = snapshot.data;
                  final attemptCount = latestSubmission?.attemptNumber ?? 0;
                  final canSubmit = assignment.hasUnlimitedAttempts ||
                      attemptCount < assignment.maxAttempts;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Submission status
                      _buildSubmissionStatus(
                        latestSubmission,
                        attemptCount,
                        assignment,
                      ),
                      const SizedBox(height: 12),

                      // Submit button
                      if (canSubmit && !assignment.isClosed)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showSubmissionDialog(
                              context,
                              ref,
                              assignment,
                              attemptCount + 1,
                            ),
                            icon: const Icon(Icons.upload_file, size: 20),
                            label: Text(
                              attemptCount == 0
                                  ? 'Submit Assignment'
                                  : 'Submit Attempt ${attemptCount + 1}',
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
                      else if (!canSubmit)
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
                              const Icon(Icons.error, color: Colors.red, size: 20),
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

  void _showAssignmentDialog(
    BuildContext context,
    WidgetRef ref,
    AssignmentEntity? assignment,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          AssignmentFormDialog(course: widget.course, assignment: assignment),
    ).then((success) {
      if (mounted && success == true) {
        ref.read(assignmentProvider.notifier).loadAssignments(widget.course.id);
      }
    });
  }

  void _deleteAssignment(
    BuildContext context,
    WidgetRef ref,
    AssignmentEntity assignment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Assignment',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${assignment.title}"? This action cannot be undone.',
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
                    .read(assignmentProvider.notifier)
                    .deleteAssignment(assignment.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${assignment.title} deleted successfully'),
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
        // Refresh the assignments to update submission status
        ref.read(assignmentProvider.notifier).loadAssignments(widget.course.id);
      }
    });
  }

  Widget _buildSubmissionStatus(
    AssignmentSubmissionEntity? submission,
    int attemptCount,
    AssignmentEntity assignment,
  ) {
    if (submission == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_actions, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              'Not submitted yet',
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

    if (submission.status == SubmissionStatus.graded) {
      statusColor = Colors.blue;
      statusIcon = Icons.grading;
      statusText = 'Graded: ${submission.grade?.toStringAsFixed(1)} points';
    } else if (submission.status == SubmissionStatus.late) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Submitted late (Attempt $attemptCount)';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Submitted on time (Attempt $attemptCount)';
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
          if (submission.status == SubmissionStatus.graded &&
              submission.feedback != null &&
              submission.feedback!.isNotEmpty) ...[
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
              submission.feedback!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Submitted: ${_formatDateTime(submission.submissionTime)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
