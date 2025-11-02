import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/enrollment_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../domain/entities/group_entity.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../../data/datasources/models/user_model.dart';
import 'group_form_dialog.dart';

/// Dialog for managing enrollments (adding/removing students) for a course
class EnrollmentManagementDialog extends ConsumerStatefulWidget {
  final CourseEntity course;
  final String semesterId;

  const EnrollmentManagementDialog({
    super.key,
    required this.course,
    required this.semesterId,
  });

  @override
  ConsumerState<EnrollmentManagementDialog> createState() =>
      _EnrollmentManagementDialogState();
}

class _EnrollmentManagementDialogState
    extends ConsumerState<EnrollmentManagementDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  GroupEntity? _selectedGroup;

  @override
  void initState() {
    super.initState();
    // Load enrollments and groups when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnrollments();
      _loadGroups();
    });
  }

  Future<void> _loadEnrollments() async {
    await ref.read(enrollmentProvider.notifier).loadEnrollments(widget.course.id);
  }

  Future<void> _loadGroups() async {
    await ref.read(groupProvider.notifier).loadGroups(widget.course.id);
  }

  Future<void> _showCreateGroupDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => GroupFormDialog(
        course: widget.course,
        semesterId: widget.semesterId,
      ),
    );

    if (result == true) {
      // Reload groups
      await _loadGroups();
      // Reload enrollments to refresh UI
      await _loadEnrollments();
    }
  }

  Future<void> _addStudentToCourse(UserEntity student) async {
    if (_selectedGroup == null) {
      setState(() {
        _errorMessage = 'Please select a group first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enrollment = EnrollmentEntity(
        id: '',
        studentId: student.uid,
        courseId: widget.course.id,
        groupId: _selectedGroup!.id,
        semesterId: widget.semesterId,
      );

      await ref.read(enrollmentProvider.notifier).createEnrollment(enrollment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.displayName} added to ${_selectedGroup!.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeEnrollment(EnrollmentEntity enrollment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Remove Student',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this student from the course?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ref.read(enrollmentProvider.notifier).deleteEnrollment(
              enrollment.id,
              widget.course.id,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student removed from course'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);
    final enrollmentsAsync = ref.watch(enrollmentProvider);
    final groupsAsync = ref.watch(groupProvider);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Enrollments',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.course.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Group selector
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No groups found. Create a group to enroll students.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showCreateGroupDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            'Create Group',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Update _selectedGroup to match the new list (fix object reference issue)
                // When groups list reloads, we need to find the group from the new list by ID
                GroupEntity? selectedGroupFromList;
                
                if (_selectedGroup != null && groups.isNotEmpty) {
                  // Try to find the group in the new list by ID
                  try {
                    selectedGroupFromList = groups.firstWhere(
                      (g) => g.id == _selectedGroup!.id,
                    );
                    // Update _selectedGroup to the new reference if different
                    if (selectedGroupFromList != _selectedGroup) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _selectedGroup = selectedGroupFromList;
                        });
                      });
                    }
                  } catch (e) {
                    // Group not found in new list, select first group
                    selectedGroupFromList = groups.first;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedGroup = selectedGroupFromList;
                      });
                    });
                  }
                } else if (groups.isNotEmpty) {
                  // No group selected yet, select first
                  selectedGroupFromList = groups.first;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedGroup = selectedGroupFromList;
                    });
                  });
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group_outlined, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        'Group:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<GroupEntity>(
                            value: selectedGroupFromList,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            items: groups.map((group) {
                              return DropdownMenuItem<GroupEntity>(
                                value: group,
                                child: Text(group.name),
                              );
                            }).toList(),
                            onChanged: (GroupEntity? value) {
                              setState(() {
                                _selectedGroup = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showCreateGroupDialog,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        color: AppColors.buttonPrimary,
                        tooltip: 'Create Group',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error loading groups: ${error.toString()}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Content: Students list and Enrollments list
            Expanded(
              child: Row(
                children: [
                  // Left: Available Students
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Students',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: studentsAsync.when(
                            data: (students) {
                              // Filter out already enrolled students
                              return enrollmentsAsync.when(
                                data: (enrollments) {
                                  final enrolledStudentIds = enrollments.map((e) => e.studentId).toSet();
                                  final availableStudents = students
                                      .where((s) => !enrolledStudentIds.contains(s.uid))
                                      .toList();

                                  if (availableStudents.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'All students are enrolled',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: availableStudents.length,
                                    itemBuilder: (context, index) {
                                      final student = availableStudents[index];
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
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    student.displayName,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    student.email,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: _isLoading || _selectedGroup == null
                                                  ? null
                                                  : () => _addStudentToCourse(student),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.buttonPrimary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                'Add',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (_, __) => const Center(child: Text('Error loading enrollments')),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, _) => Center(
                              child: Text(
                                'Error: ${error.toString()}',
                                style: GoogleFonts.inter(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right: Enrolled Students
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enrolled Students',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: enrollmentsAsync.when(
                            data: (enrollments) {
                              if (enrollments.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No students enrolled yet',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }

                              // Get student info for each enrollment
                              return FutureBuilder<List<Map<String, dynamic>>>(
                                future: _getEnrollmentDetails(enrollments),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  if (!snapshot.hasData) {
                                    return const Center(child: Text('No data'));
                                  }

                                  final enrollmentDetails = snapshot.data!;

                                  return ListView.builder(
                                    itemCount: enrollmentDetails.length,
                                    itemBuilder: (context, index) {
                                      final detail = enrollmentDetails[index];
                                      final enrollment = detail['enrollment'] as EnrollmentEntity;
                                      final student = detail['student'] as UserEntity?;
                                      final groupName = detail['groupName'] as String?;

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
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    student?.displayName ?? 'Unknown',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    student?.email ?? '',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.buttonPrimary.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Group: ${groupName ?? "Unknown"}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: AppColors.buttonPrimary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : () => _removeEnrollment(enrollment),
                                              icon: const Icon(Icons.delete_outline, size: 18),
                                              color: Colors.red,
                                              tooltip: 'Remove',
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, _) => Center(
                              child: Text(
                                'Error: ${error.toString()}',
                                style: GoogleFonts.inter(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Footer buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getEnrollmentDetails(
    List<EnrollmentEntity> enrollments,
  ) async {
    final remoteDataSource = ref.read(enrollmentRemoteDataSourceProvider);
    final details = <Map<String, dynamic>>[];

    for (final enrollment in enrollments) {
      // Get student info
      final students = await remoteDataSource.getAllStudents();
      final student = students.firstWhere(
        (s) => s.uid == enrollment.studentId,
        orElse: () => students.first, // Fallback (shouldn't happen)
      );

      // Get group info
      final group = await remoteDataSource.getGroupById(enrollment.groupId);

      details.add({
        'enrollment': enrollment,
        'student': UserModel.fromJson({
          'uid': student.uid,
          'email': student.email,
          'displayName': student.displayName,
          'role': 'student',
          'avatarUrl': student.avatarUrl,
        }).toEntity(),
        'groupName': group?.name ?? 'Unknown',
      });
    }

    return details;
  }
}

