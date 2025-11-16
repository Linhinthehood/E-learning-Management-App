import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/course_entity.dart';
import '../../common/styles/colors.dart';
import '../../providers/semester_provider.dart';
import '../../features/course/tabs/announcements_tab.dart';
import '../../features/course/tabs/assignments_tab.dart';
import '../../features/course/tabs/quizzes_tab.dart';
import '../../features/course/tabs/question_banks_tab.dart';
import '../../features/course/tabs/materials_tab.dart';
import '../../features/course/tabs/forum_tab.dart';
import '../../features/course/tabs/people_tab.dart';

/// Instructor Course Detail Screen - Full management view for instructors
class InstructorCourseDetailScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final int initialTabIndex;

  const InstructorCourseDetailScreen({
    super.key,
    required this.course,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<InstructorCourseDetailScreen> createState() =>
      _InstructorCourseDetailScreenState();
}

class _InstructorCourseDetailScreenState
    extends ConsumerState<InstructorCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Instructor has 7 tabs (includes Question Banks)
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fetch semester to check if it's past
    final semesterAsync = ref.watch(semesterProvider);

    return semesterAsync.when(
      data: (semesters) {
        // Find the semester for this course
        final semester = semesters
            .where((s) => s.id == widget.course.semesterId)
            .firstOrNull;
        final bool isReadOnly = semester?.isPast ?? false;

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
                  widget.course.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      widget.course.code,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isReadOnly) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Text(
                          'READ-ONLY',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.buttonPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.buttonPrimary,
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Stream', icon: Icon(Icons.stream, size: 20)),
                Tab(text: 'Classwork', icon: Icon(Icons.assignment, size: 20)),
                Tab(text: 'Quizzes', icon: Icon(Icons.quiz, size: 20)),
                Tab(
                  text: 'Questions',
                  icon: Icon(Icons.library_books, size: 20),
                ),
                Tab(text: 'Materials', icon: Icon(Icons.folder, size: 20)),
                Tab(text: 'Forum', icon: Icon(Icons.forum, size: 20)),
                Tab(text: 'People', icon: Icon(Icons.people, size: 20)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              AnnouncementsTab(course: widget.course, isStudent: false),
              AssignmentsTab(
                course: widget.course,
                isReadOnly: isReadOnly,
                isStudent: false,
              ),
              QuizzesTab(
                course: widget.course,
                isReadOnly: isReadOnly,
                isStudent: false,
              ),
              QuestionBanksTab(course: widget.course),
              MaterialsTab(course: widget.course, isStudent: false),
              ForumTab(course: widget.course),
              PeopleTab(course: widget.course),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) {
        // Default to not read-only if error
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
                  widget.course.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.course.code,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.buttonPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.buttonPrimary,
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Stream', icon: Icon(Icons.stream, size: 20)),
                Tab(text: 'Classwork', icon: Icon(Icons.assignment, size: 20)),
                Tab(text: 'Quizzes', icon: Icon(Icons.quiz, size: 20)),
                Tab(
                  text: 'Questions',
                  icon: Icon(Icons.library_books, size: 20),
                ),
                Tab(text: 'Materials', icon: Icon(Icons.folder, size: 20)),
                Tab(text: 'Forum', icon: Icon(Icons.forum, size: 20)),
                Tab(text: 'People', icon: Icon(Icons.people, size: 20)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              AnnouncementsTab(course: widget.course, isStudent: false),
              AssignmentsTab(
                course: widget.course,
                isReadOnly: false,
                isStudent: false,
              ),
              QuizzesTab(
                course: widget.course,
                isReadOnly: false,
                isStudent: false,
              ),
              QuestionBanksTab(course: widget.course),
              MaterialsTab(course: widget.course, isStudent: false),
              ForumTab(course: widget.course),
              PeopleTab(course: widget.course),
            ],
          ),
        );
      },
    );
  }
}
