import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../messaging/chat_screen.dart';
import '../csv_import/student_csv_import_screen.dart';
import 'widgets/student_form_dialog.dart';

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState
    extends ConsumerState<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Name (A-Z)';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _applyFiltersAndSort(List<dynamic> students) {
    var filtered = students.where((student) {
      // Search filter
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

    // Sort
    switch (_sortBy) {
      case 'Name (A-Z)':
        filtered.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case 'Name (Z-A)':
        filtered.sort((a, b) => b.displayName.compareTo(a.displayName));
        break;
      case 'Email (A-Z)':
        filtered.sort((a, b) => a.email.compareTo(b.email));
        break;
      case 'Email (Z-A)':
        filtered.sort((a, b) => b.email.compareTo(a.email));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Management',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create and manage student accounts',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        // Navigate to CSV import screen and wait for result
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentCsvImportScreen(),
                          ),
                        );

                        // Refresh student list after import
                        ref.invalidate(studentProvider);
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
                          horizontal: 24,
                          vertical: 16,
                        ),
                        side: BorderSide(color: AppColors.buttonPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showStudentDialog(context, ref),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        'Add Student',
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
              ],
            ),
            const SizedBox(height: 32),

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

            // Sort control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      'Name (A-Z)',
                      'Name (Z-A)',
                      'Email (A-Z)',
                      'Email (Z-A)',
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
            const SizedBox(height: 24),

            // Students list
            Expanded(
              child: studentsState.when(
                data: (students) {
                  final filteredStudents = _applyFiltersAndSort(students);

                  if (students.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No students yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Add Student" to create your first student account',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredStudents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No students found',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    color: AppColors.cardBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.buttonPrimary,
                            child: Text(
                              student.displayName[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            student.email,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.message_outlined),
                                color: AppColors.buttonPrimary,
                                onPressed: () => _startChatWithStudent(
                                  context,
                                  ref,
                                  student,
                                ),
                                tooltip: 'Message student',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showStudentDialog(
                                  context,
                                  ref,
                                  student: student,
                                ),
                                tooltip: 'Edit student',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                onPressed: () => _deleteStudent(
                                  context,
                                  ref,
                                  student.uid,
                                  student.displayName,
                                ),
                                tooltip: 'Delete student',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading students',
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
                        onPressed: () =>
                            ref.read(studentProvider.notifier).loadStudents(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDialog(
    BuildContext context,
    WidgetRef ref, {
    dynamic student,
  }) {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(student: student),
    );
  }

  void _deleteStudent(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Student',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete $name? This action cannot be undone.',
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
                await ref.read(studentProvider.notifier).deleteStudent(userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
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

  Future<void> _startChatWithStudent(
    BuildContext context,
    WidgetRef ref,
    dynamic student,
  ) async {
    final userAsync = ref.read(authProvider);
    final user = userAsync.value;

    if (user == null) {
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
}
