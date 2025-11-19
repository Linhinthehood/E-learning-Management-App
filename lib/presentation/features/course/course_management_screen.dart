import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/course_entity.dart';
import '../../../domain/entities/semester_entity.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/skeleton_widgets.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../csv_import/course_csv_import_screen.dart';
import 'widgets/course_form_dialog.dart';
import 'widgets/enrollment_management_dialog.dart';
import '../instructor/course_detail_screen.dart';

/// Course Management Screen for instructors
class CourseManagementScreen extends ConsumerStatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  ConsumerState<CourseManagementScreen> createState() =>
      _CourseManagementScreenState();
}

class _CourseManagementScreenState
    extends ConsumerState<CourseManagementScreen> {
  SemesterEntity? _selectedSemester;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Name (A-Z)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSemester();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CourseEntity> _applyFiltersAndSort(List<CourseEntity> courses) {
    var filtered = courses.where((course) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            course.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            course.code.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }
      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Name (A-Z)':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name (Z-A)':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Code (A-Z)':
        filtered.sort((a, b) => a.code.compareTo(b.code));
        break;
      case 'Code (Z-A)':
        filtered.sort((a, b) => b.code.compareTo(a.code));
        break;
      case 'Sessions (Low-High)':
        filtered.sort((a, b) => a.sessions.compareTo(b.sessions));
        break;
      case 'Sessions (High-Low)':
        filtered.sort((a, b) => b.sessions.compareTo(a.sessions));
        break;
    }

    return filtered;
  }

  Future<void> _initializeSemester() async {
    final semestersAsync = ref.read(semesterProvider);
    await semestersAsync.when(
      data: (semesters) {
        if (semesters.isNotEmpty) {
          final activeSemester = semesters.firstWhere(
            (s) => s.isActive,
            orElse: () => semesters.first,
          );
          setState(() {
            _selectedSemester = activeSemester;
          });
          _loadCourses();
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _loadCourses() {
    if (_selectedSemester != null) {
      ref.read(courseProvider.notifier).loadCourses(_selectedSemester!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semestersAsync = ref.watch(semesterProvider);
    final coursesAsync = ref.watch(courseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Management',
                        style: GoogleFonts.inter(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your courses',
                        style: GoogleFonts.inter(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (MediaQuery.of(context).size.width >= 600)
                        OutlinedButton.icon(
                      onPressed: () async {
                        // Navigate to CSV import screen and wait for result
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CourseCsvImportScreen(),
                          ),
                        );

                        // Refresh course list after import
                        if (_selectedSemester != null) {
                          ref
                              .read(courseProvider.notifier)
                              .loadCourses(_selectedSemester!.id);
                        }
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
                      if (MediaQuery.of(context).size.width >= 600)
                        const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_selectedSemester == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a semester first'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          _showCourseDialog(null);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          MediaQuery.of(context).size.width < 600 ? 'Add' : 'Add Course',
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
                )),
              ],
            ),
          ),
          // Semester Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildSemesterSelector(semestersAsync),
          ),
          const SizedBox(height: 24),
          // Search and Sort controls
          if (_selectedSemester != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search courses by name or code...',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
                      'Code (A-Z)',
                      'Code (Z-A)',
                      'Sessions (Low-High)',
                      'Sessions (High-Low)',
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
          ],
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _selectedSemester == null
                  ? Center(
                      child: Text(
                        'Please select a semester',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : _buildCoursesList(coursesAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector(
    AsyncValue<List<SemesterEntity>> semestersAsync,
  ) {
    return semestersAsync.when(
      data: (semesters) {
        if (semesters.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'No semesters available. Please create a semester first.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                'Semester:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SemesterEntity>(
                    value: _selectedSemester,
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textPrimary,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    items: semesters.map((semester) {
                      return DropdownMenuItem<SemesterEntity>(
                        value: semester,
                        child: Row(
                          children: [
                            Expanded(child: Text(semester.name)),
                            if (semester.isActive)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Active',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (SemesterEntity? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSemester = newValue;
                        });
                        _loadCourses();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SkeletonSemesterSelector(),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            'Error loading semesters: ${error.toString()}',
            style: GoogleFonts.inter(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList(AsyncValue<List<CourseEntity>> coursesAsync) {
    return coursesAsync.when(
      data: (courses) {
        final filteredCourses = _applyFiltersAndSort(courses);

        if (courses.isEmpty) {
          return _buildEmptyState();
        }

        if (filteredCourses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No courses found',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildCourseGrid(filteredCourses);
      },
      loading: () => const SkeletonCourseGrid(),
      error: (error, _) => _buildErrorState(error),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No courses yet',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first course for this semester',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCourseDialog(null),
            icon: const Icon(Icons.add),
            label: Text(
              'Add Course',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseGrid(List<CourseEntity> courses) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid columns based on screen width
        int crossAxisCount;
        double childAspectRatio;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1; // Mobile: 1 column
          childAspectRatio = 0.75; // Taller cards on mobile
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2; // Tablet: 2 columns
          childAspectRatio = 0.9;
        } else if (constraints.maxWidth < 1400) {
          crossAxisCount = 3; // Desktop: 3 columns
          childAspectRatio = 1.0;
        } else {
          crossAxisCount = 4; // Large desktop: 4 columns
          childAspectRatio = 1.1;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _buildCourseCard(course);
          },
        );
      },
    );
  }

  Widget _buildCourseCard(CourseEntity course) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image or placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child:
                  course.coverImageUrl != null &&
                      course.coverImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        course.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      ),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          // Course info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${course.code}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // View Course button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                InstructorCourseDetailScreen(course: course),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Course',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.sessions} sessions',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _showEnrollmentDialog(course),
                            icon: const Icon(
                              Icons.group_add_outlined,
                              size: 18,
                            ),
                            color: AppColors.buttonPrimary,
                            tooltip: 'Manage Students',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showCourseDialog(course),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: AppColors.textPrimary,
                            tooltip: 'Edit',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showDeleteConfirmation(course),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: Colors.red,
                            tooltip: 'Delete',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.book_outlined,
        size: 40,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Error loading courses',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadCourses,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnrollmentDialog(CourseEntity course) {
    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a semester first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EnrollmentManagementDialog(
        course: course,
        semesterId: _selectedSemester!.id,
      ),
    );
  }

  void _showCourseDialog(CourseEntity? course) {
    showDialog(
      context: context,
      builder: (context) => CourseFormDialog(course: course),
    ).then((result) {
      // Refresh courses after dialog closes if course was created/updated
      if (result == true && _selectedSemester != null) {
        _loadCourses();
      }
    });
  }

  void _showDeleteConfirmation(CourseEntity course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Delete Course',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${course.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!mounted) return;
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              try {
                await ref
                    .read(courseProvider.notifier)
                    .deleteCourse(course.id, course.semesterId);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Course deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
