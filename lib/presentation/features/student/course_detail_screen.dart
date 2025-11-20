import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/course_entity.dart';
import '../../common/styles/colors.dart';
import '../../common/widgets/skeleton_widgets.dart';
import '../../providers/semester_provider.dart';
import '../../features/course/tabs/announcements_tab.dart';
import '../../features/course/tabs/classwork_tab.dart';
import '../../features/course/tabs/people_tab.dart';

/// Student Course Detail Screen - Read-only view for students
class StudentCourseDetailScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final int initialTabIndex;

  const StudentCourseDetailScreen({
    super.key,
    required this.course,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState
    extends ConsumerState<StudentCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Student has 3 tabs: Stream, Classwork, People
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
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
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.course.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            widget.course.code,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (isReadOnly) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'READ-ONLY',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
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
                Tab(text: 'Stream', icon: Icon(Icons.stream, size: 18)),
                Tab(text: 'Classwork', icon: Icon(Icons.assignment, size: 18)),
                Tab(text: 'People', icon: Icon(Icons.people, size: 18)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              AnnouncementsTab(course: widget.course, isStudent: true),
              ClassworkTab(
                course: widget.course,
                isReadOnly: isReadOnly,
                isStudent: true,
              ),
              PeopleTab(course: widget.course),
            ],
          ),
        );
      },
      loading: () => const SkeletonCourseDetailScreen(),
      error: (_, __) {
        // Default to read-only if error
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.course.name,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.course.code,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                Tab(text: 'Stream', icon: Icon(Icons.stream, size: 18)),
                Tab(text: 'Classwork', icon: Icon(Icons.assignment, size: 18)),
                Tab(text: 'People', icon: Icon(Icons.people, size: 18)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              AnnouncementsTab(course: widget.course, isStudent: true),
              ClassworkTab(
                course: widget.course,
                isReadOnly: true,
                isStudent: true,
              ),
              PeopleTab(course: widget.course),
            ],
          ),
        );
      },
    );
  }
}
