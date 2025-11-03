import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/course_entity.dart';
import '../../common/styles/colors.dart';
import 'tabs/announcements_tab.dart';
import 'tabs/assignments_tab.dart';
import 'tabs/quizzes_tab.dart';
import 'tabs/question_banks_tab.dart';
import 'tabs/materials_tab.dart';
import 'tabs/people_tab.dart';

/// Course Detail Screen - Main screen for managing course content
class CourseDetailScreen extends ConsumerStatefulWidget {
  final CourseEntity course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Tab(text: 'Questions', icon: Icon(Icons.library_books, size: 20)),
            Tab(text: 'Materials', icon: Icon(Icons.folder, size: 20)),
            Tab(text: 'People', icon: Icon(Icons.people, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AnnouncementsTab(course: widget.course),
          AssignmentsTab(course: widget.course),
          QuizzesTab(course: widget.course),
          QuestionBanksTab(course: widget.course),
          MaterialsTab(course: widget.course),
          PeopleTab(course: widget.course),
        ],
      ),
    );
  }
}
