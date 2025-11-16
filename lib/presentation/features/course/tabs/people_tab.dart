import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/group_entity.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../messaging/chat_screen.dart';
import '../../csv_import/group_csv_import_screen.dart';
import '../widgets/enrollment_management_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// People tab - displays instructor, groups, and students
class PeopleTab extends ConsumerStatefulWidget {
  final CourseEntity course;

  const PeopleTab({super.key, required this.course});

  @override
  ConsumerState<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends ConsumerState<PeopleTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterGroup = 'All Groups';

  @override
  void initState() {
    super.initState();
    // Load groups and enrollments when tab is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(groupProvider.notifier).loadGroups(widget.course.id);
        ref.read(enrollmentProvider.notifier).loadEnrollments(widget.course.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserEntity> _filterStudents(List<UserEntity> students) {
    return students.where((student) {
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            student.displayName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            student.email.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupProvider);
    final enrollmentsAsync = ref.watch(enrollmentProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final userAsync = ref.watch(authProvider);
    final isInstructor = userAsync.value?.role == UserRole.instructor;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'People',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isInstructor)
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Navigate to CSV import screen and wait for result
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupCsvImportScreen(),
                          ),
                        );

                        // Refresh groups and enrollments after import
                        ref
                            .read(groupProvider.notifier)
                            .loadGroups(widget.course.id);
                        ref
                            .read(enrollmentProvider.notifier)
                            .loadEnrollments(widget.course.id);
                      },
                      icon: const Icon(Icons.upload_file, size: 20),
                      label: Text(
                        'Import CSV',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.buttonPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        side: BorderSide(color: AppColors.buttonPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => EnrollmentManagementDialog(
                            course: widget.course,
                            semesterId: widget.course.semesterId,
                          ),
                        );
                      },
                      icon: const Icon(Icons.group_add, size: 20),
                      label: Text(
                        'Manage Students',
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Instructor Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildInstructorSection(),
        ),
        const SizedBox(height: 24),

        // Divider
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(color: AppColors.border),
        ),
        const SizedBox(height: 16),

        // Groups and Students Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.group, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Groups & Students',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search students by name or email...',
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
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Groups List
        Expanded(
          child: groupsAsync.when(
            data: (groups) => enrollmentsAsync.when(
              data: (enrollments) => studentsAsync.when(
                data: (students) {
                  if (groups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No groups yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (isInstructor) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Create groups and enroll students to get started',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final groupEnrollments = enrollments
                          .where((e) => e.groupId == group.id)
                          .toList();
                      final groupStudents = students
                          .where(
                            (student) => groupEnrollments.any(
                              (e) => e.studentId == student.uid,
                            ),
                          )
                          .toList();

                      // Apply search filter to group students
                      final filteredGroupStudents = _filterStudents(
                        groupStudents,
                      );

                      // Skip groups with no matching students if search is active
                      if (_searchQuery.isNotEmpty &&
                          filteredGroupStudents.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return _buildGroupCard(
                        group,
                        filteredGroupStudents,
                        groupEnrollments.length,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading students',
                    style: GoogleFonts.inter(color: Colors.red),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Error loading enrollments',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading groups',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(groupProvider.notifier)
                          .loadGroups(widget.course.id);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _getInstructorName(String instructorId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(instructorId)
          .get();
      if (userDoc.exists) {
        return userDoc.data()?['displayName'] as String? ?? 'Instructor';
      }
    } catch (e) {
      // Error getting instructor name
    }
    return 'Instructor';
  }

  Future<void> _startChatWithInstructor(BuildContext context) async {
    final userAsync = ref.read(authProvider);
    final user = userAsync.value;

    if (user == null || user.role != UserRole.student) {
      return;
    }

    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Get or create chat
      final chat = await ref
          .read(chatProvider.notifier)
          .getOrCreateChat(user.uid, widget.course.instructorId);

      // Get instructor name
      final instructorName = await _getInstructorName(
        widget.course.instructorId,
      );

      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.id,
              participantId: widget.course.instructorId,
              participantName: instructorName ?? 'Instructor',
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startChatWithStudent(
    BuildContext context,
    UserEntity student,
  ) async {
    final userAsync = ref.read(authProvider);
    final user = userAsync.value;

    if (user == null || user.role != UserRole.instructor) {
      return;
    }

    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Get or create chat (studentId, instructorId)
      final chat = await ref
          .read(chatProvider.notifier)
          .getOrCreateChat(student.uid, user.uid);

      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.id,
              participantId: student.uid,
              participantName: student.displayName,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInstructorSection() {
    final userAsync = ref.watch(authProvider);
    final isStudent = userAsync.value?.role == UserRole.student;

    return FutureBuilder<String?>(
      future: _getInstructorName(widget.course.instructorId),
      builder: (context, snapshot) {
        final instructorName = snapshot.data ?? 'Instructor';

        return Card(
          color: AppColors.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Instructor Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.buttonPrimary.withValues(
                    alpha: 0.2,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: AppColors.buttonPrimary,
                  ),
                ),
                const SizedBox(width: 16),

                // Instructor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Instructor',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.buttonPrimary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Teacher',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.buttonPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instructorName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.course.instructorId}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Message button (only for students)
                if (isStudent)
                  IconButton(
                    icon: const Icon(
                      Icons.message,
                      color: AppColors.buttonPrimary,
                    ),
                    onPressed: () => _startChatWithInstructor(context),
                    tooltip: 'Message instructor',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(
    GroupEntity group,
    List<UserEntity> students,
    int totalStudents,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          child: const Icon(
            Icons.group,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          group.name,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$totalStudents student${totalStudents != 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        children: [
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No students enrolled in this group',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...students.map((student) => _buildStudentItem(student)),
        ],
      ),
    );
  }

  Widget _buildStudentItem(UserEntity student) {
    final userAsync = ref.watch(authProvider);
    final isInstructor = userAsync.value?.role == UserRole.instructor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Student Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.background,
            child: Text(
              student.displayName.isNotEmpty
                  ? student.displayName[0].toUpperCase()
                  : 'S',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
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

          // Student Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Student',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Message button (only for instructors)
          if (isInstructor) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.message,
                size: 20,
                color: AppColors.buttonPrimary,
              ),
              onPressed: () => _startChatWithStudent(context, student),
              tooltip: 'Message student',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
