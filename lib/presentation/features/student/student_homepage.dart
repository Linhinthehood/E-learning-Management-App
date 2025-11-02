import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/course_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../../domain/entities/semester_entity.dart';
import '../../../domain/entities/course_entity.dart';

/// Student Homepage - Displays enrolled courses with semester switcher
class StudentHomepage extends ConsumerStatefulWidget {
  const StudentHomepage({super.key});

  @override
  ConsumerState<StudentHomepage> createState() => _StudentHomepageState();
}

class _StudentHomepageState extends ConsumerState<StudentHomepage> {
  SemesterEntity? _selectedSemester;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSemester();
    });
  }

  Future<void> _initializeSemester() async {
    // Wait for semesters to load, then select active semester
    final semestersAsync = ref.read(semesterProvider);
    await semestersAsync.when(
      data: (semesters) {
        if (semesters.isNotEmpty) {
          // Find active semester or use the latest one
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
    final userAsync = ref.read(authProvider);
    userAsync.whenData((user) {
      if (user != null && _selectedSemester != null) {
        ref.read(studentCoursesProvider.notifier).loadCourses(
              user.uid,
              _selectedSemester!.id,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    final semestersAsync = ref.watch(semesterProvider);
    final coursesAsync = ref.watch(studentCoursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting and semester switcher
                _buildHeader(user.displayName),
                const SizedBox(height: 30),

                // Semester Switcher
                _buildSemesterSwitcher(semestersAsync),

                const SizedBox(height: 40),

                // Courses Grid
                _buildCoursesSection(coursesAsync),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading user')),
      ),
    );
  }

  Widget _buildHeader(String displayName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello ${displayName}!',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Welcome to your courses',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSemesterSwitcher(AsyncValue<List<SemesterEntity>> semestersAsync) {
    return semestersAsync.when(
      data: (semesters) {
        if (semesters.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'No semesters available',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        // If no semester selected, select the first one
        if (_selectedSemester == null) {
          final activeSemester = semesters.firstWhere(
            (s) => s.isActive,
            orElse: () => semesters.first,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedSemester = activeSemester;
            });
            _loadCourses();
          });
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
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    items: semesters.map((semester) {
                      return DropdownMenuItem<SemesterEntity>(
                        value: semester,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(semester.name),
                            ),
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
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
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
            style: GoogleFonts.inter(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesSection(AsyncValue<List<CourseEntity>> coursesAsync) {
    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(60),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.book_outlined,
                  size: 80,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 20),
                Text(
                  'No courses enrolled',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You are not enrolled in any courses for this semester.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Courses (${courses.length})',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // Course cards grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.1,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return FutureBuilder<Map<String, String>?>(
                  future: _getInstructorInfo(course.instructorId),
                  builder: (context, snapshot) {
                    final instructorName = snapshot.data?['name'] ?? 'Unknown Instructor';
                    final colors = [
                      const Color(0xFFFF6B6B),
                      const Color(0xFF4ECDC4),
                      const Color(0xFFE056FD),
                      const Color(0xFFFFA726),
                      const Color(0xFF42A5F5),
                      const Color(0xFF95E1D3),
                    ];
                    final color = colors[index % colors.length];

                    return CourseCard(
                      title: course.name,
                      instructor: instructorName,
                      courseCode: course.code,
                      color: color,
                      students: 0, // TODO: Get actual student count
                      assignments: 0, // TODO: Get actual assignment count
                    );
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading courses',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> _getInstructorInfo(String instructorId) async {
    try {
      final repository = ref.read(courseRepositoryProvider);
      return await repository.getInstructorInfo(instructorId);
    } catch (e) {
      return null;
    }
  }
}

