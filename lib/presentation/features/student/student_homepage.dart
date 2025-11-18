import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/offline_indicator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/semester_provider.dart';
import '../../providers/student_dashboard_provider.dart';
import '../../../domain/entities/semester_entity.dart';
import 'widgets/dashboard_statistics_cards.dart';
import 'widgets/upcoming_deadlines_widget.dart';
import 'widgets/course_progress_widget.dart';
import 'widgets/recent_grades_widget.dart';
import 'course_detail_screen.dart';

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
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authProvider);
    final semestersAsync = ref.watch(semesterProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline Indicator
              const OfflineIndicator(),

              // Greeting Section
              _buildGreeting(user.displayName),
              const SizedBox(height: 30),

              // Semester Switcher
              _buildSemesterSwitcher(semestersAsync),
              const SizedBox(height: 20),

              // Past Semester Warning Banner
              if (_selectedSemester != null && _selectedSemester!.isPast)
                _buildPastSemesterWarning(),

              const SizedBox(height: 20),

              // Dashboard Data
              if (_selectedSemester != null)
                _buildDashboardContent(user.uid, _selectedSemester!.id),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading user')),
    );
  }

  Widget _buildGreeting(String displayName) {
    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $displayName!',
                style: GoogleFonts.inter(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 5),
              Text(
                "It's good to see you again.",
                style: GoogleFonts.inter(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 13 : 15,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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

  Widget _buildDashboardContent(String studentId, String semesterId) {
    final dashboardAsync = ref.watch(
      studentDashboardProvider(
        StudentDashboardParams(studentId: studentId, semesterId: semesterId),
      ),
    );

    return dashboardAsync.when(
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            DashboardStatisticsCards(statistics: data.statistics),
            const SizedBox(height: 24),

            // Main Content - Responsive Layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1200) {
                  // Wide layout: 2 columns
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Upcoming Deadlines and Recent Grades
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            UpcomingDeadlinesWidget(
                              upcomingAssignments: data.upcomingAssignments,
                              upcomingQuizzes: data.upcomingQuizzes,
                              courseMap: data.courseMap,
                              onAssignmentTap: (course, assignmentId) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentCourseDetailScreen(
                                          course: course,
                                        ),
                                  ),
                                );
                              },
                              onQuizTap: (course, quizId) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentCourseDetailScreen(
                                          course: course,
                                        ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            RecentGradesWidget(
                              recentGrades: data.recentGrades,
                              courseMap: data.courseMap,
                              onTap: (course, assignmentId) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentCourseDetailScreen(
                                          course: course,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Course Progress
                      Expanded(
                        flex: 2,
                        child: CourseProgressWidget(
                          courseProgress: data.courseProgress,
                          courseMap: data.courseMap,
                          onCourseTap: (course) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StudentCourseDetailScreen(course: course),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  // Narrow layout: Stack vertically
                  return Column(
                    children: [
                      UpcomingDeadlinesWidget(
                        upcomingAssignments: data.upcomingAssignments,
                        upcomingQuizzes: data.upcomingQuizzes,
                        courseMap: data.courseMap,
                        onAssignmentTap: (course, assignmentId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StudentCourseDetailScreen(course: course),
                            ),
                          );
                        },
                        onQuizTap: (course, quizId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StudentCourseDetailScreen(course: course),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      RecentGradesWidget(
                        recentGrades: data.recentGrades,
                        courseMap: data.courseMap,
                        onTap: (course, assignmentId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StudentCourseDetailScreen(course: course),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      CourseProgressWidget(
                        courseProgress: data.courseProgress,
                        courseMap: data.courseMap,
                        onCourseTap: (course) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StudentCourseDetailScreen(course: course),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
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
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard data',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.inter(fontSize: 12, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build warning banner for past semesters
  Widget _buildPastSemesterWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[800],
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Viewing Past Semester',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You are viewing a past semester. You cannot submit assignments or take quizzes for this semester. You can only view materials and grades.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
