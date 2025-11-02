import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/course_list_item.dart';
import '../../common/widgets/right_sidebar.dart';
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
  int _selectedTab = 0;

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
        ref
            .read(studentCoursesProvider.notifier)
            .loadCourses(user.uid, _selectedSemester!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    final semestersAsync = ref.watch(semesterProvider);
    final coursesAsync = ref.watch(studentCoursesProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Row(
          children: [
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting Section
                      _buildGreeting(user.displayName),
                      const SizedBox(height: 30),

                      // Featured Course
                      coursesAsync.when(
                        data: (courses) {
                          if (courses.isNotEmpty) {
                            return Column(
                              children: [
                                _buildFeaturedCourse(courses.first),
                                const SizedBox(height: 40),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Semester Switcher
                      _buildSemesterSwitcher(semestersAsync),
                      const SizedBox(height: 30),

                      // Courses Section with Tabs
                      _buildCoursesSection(coursesAsync),
                    ],
                  ),
                ),
              ),
            ),
            // Right Sidebar
            const RightSidebar(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }

  Widget _buildGreeting(String displayName) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello $displayName!',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "It's good to see you again.",
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 30),
        // Illustration
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.borderLight,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Text('👋', style: TextStyle(fontSize: 60)),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCourse(CourseEntity course) {
    return FutureBuilder<Map<String, String>?>(
      future: _getInstructorInfo(course.instructorId),
      builder: (context, snapshot) {
        final instructorName = snapshot.data?['name'] ?? 'Unknown Instructor';

        return Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    _getCourseEmoji(course.name),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'by $instructorName',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time, size: 20),
              ),
              const SizedBox(width: 15),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSemesterSwitcher(
    AsyncValue<List<SemesterEntity>> semestersAsync,
  ) {
    return semestersAsync.when(
      data: (semesters) {
        if (semesters.isEmpty) {
          return const SizedBox.shrink();
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
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCoursesSection(AsyncValue<List<CourseEntity>> coursesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Courses',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        // Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTab('All Courses', 0),
              const SizedBox(width: 30),
              _buildTab('Courses This Semester', 1),
              const SizedBox(width: 30),
              _buildTab('Need Homework Courses', 2),
              const SizedBox(width: 30),
              _buildTab('Course With Upcoming Test', 3),
            ],
          ),
        ),
        const SizedBox(height: 25),
        // Course list
        coursesAsync.when(
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

            final colors = [
              const Color(0xFFFF6B6B),
              const Color(0xFF4ECDC4),
              const Color(0xFFE056FD),
              const Color(0xFFFFA726),
              const Color(0xFF42A5F5),
              const Color(0xFF95E1D3),
            ];

            return Column(
              children: courses.asMap().entries.map((entry) {
                final index = entry.key;
                final course = entry.value;
                final color = colors[index % colors.length];

                return FutureBuilder<Map<String, String>?>(
                  future: _getInstructorInfo(course.instructorId),
                  builder: (context, snapshot) {
                    final instructorName =
                        snapshot.data?['name'] ?? 'Unknown Instructor';

                    return CourseListItem(
                      title: course.name,
                      instructor: instructorName,
                      duration: '${course.sessions} Sessions',
                      rating: 4.5,
                      icon: _getCourseIcon(course.name),
                      iconColor: color,
                    );
                  },
                );
              }).toList(),
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
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
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

  String _getCourseEmoji(String courseName) {
    final name = courseName.toLowerCase();
    if (name.contains('math') || name.contains('calculus')) return '📐';
    if (name.contains('physics')) return '⚛️';
    if (name.contains('chemistry')) return '🧪';
    if (name.contains('biology')) return '🧬';
    if (name.contains('computer') || name.contains('programming')) return '💻';
    if (name.contains('english') || name.contains('literature')) return '📚';
    if (name.contains('history')) return '📜';
    if (name.contains('art')) return '🎨';
    if (name.contains('music')) return '🎵';
    if (name.contains('spanish') || name.contains('french')) return '🗣️';
    return '📖';
  }

  IconData _getCourseIcon(String courseName) {
    final name = courseName.toLowerCase();
    if (name.contains('math') || name.contains('calculus'))
      return Icons.calculate;
    if (name.contains('physics')) return Icons.science;
    if (name.contains('chemistry')) return Icons.science;
    if (name.contains('biology')) return Icons.biotech;
    if (name.contains('computer') || name.contains('programming'))
      return Icons.computer;
    if (name.contains('english') || name.contains('literature'))
      return Icons.book;
    if (name.contains('history')) return Icons.history_edu;
    if (name.contains('art')) return Icons.brush;
    if (name.contains('music')) return Icons.music_note;
    if (name.contains('spanish') || name.contains('french'))
      return Icons.language;
    if (name.contains('design') || name.contains('figma'))
      return Icons.design_services;
    if (name.contains('photo')) return Icons.camera_alt;
    return Icons.school;
  }
}
