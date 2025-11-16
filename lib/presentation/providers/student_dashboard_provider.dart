import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/quiz_entity.dart';
import '../../domain/entities/assignment_submission_entity.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/i_assignment_repository.dart';
import '../../domain/repositories/i_quiz_repository.dart';
import '../../domain/repositories/i_assignment_submission_repository.dart';
import '../../domain/repositories/i_quiz_attempt_repository.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../../domain/repositories/i_enrollment_repository.dart';
import '../../data/repositories/assignment_repository_impl.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../data/repositories/assignment_submission_repository_impl.dart';
import '../../data/repositories/quiz_attempt_repository_impl.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/enrollment_repository_impl.dart';
import '../../data/datasources/remote/assignment_remote_datasource.dart';
import '../../data/datasources/remote/quiz_remote_datasource.dart';
import '../../data/datasources/remote/assignment_submission_remote_datasource.dart';
import '../../data/datasources/remote/quiz_attempt_remote_datasource.dart';
import '../../data/datasources/remote/course_remote_datasource.dart';
import '../../data/datasources/remote/enrollment_remote_datasource.dart';

/// Student Dashboard Data Model
class StudentDashboardData {
  final List<AssignmentEntity> upcomingAssignments;
  final List<QuizEntity> upcomingQuizzes;
  final List<AssignmentSubmissionEntity> recentGrades;
  final Map<String, CourseProgress> courseProgress;
  final Map<String, CourseEntity> courseMap;
  final Statistics statistics;

  StudentDashboardData({
    required this.upcomingAssignments,
    required this.upcomingQuizzes,
    required this.recentGrades,
    required this.courseProgress,
    required this.courseMap,
    required this.statistics,
  });
}

/// Course Progress Data
class CourseProgress {
  final String courseId;
  final String courseName;
  final int totalAssignments;
  final int submittedAssignments;
  final int totalQuizzes;
  final int completedQuizzes;
  final double averageGrade;

  CourseProgress({
    required this.courseId,
    required this.courseName,
    required this.totalAssignments,
    required this.submittedAssignments,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.averageGrade,
  });

  double get assignmentProgress {
    if (totalAssignments == 0) return 0.0;
    return submittedAssignments / totalAssignments;
  }

  double get quizProgress {
    if (totalQuizzes == 0) return 0.0;
    return completedQuizzes / totalQuizzes;
  }
}

/// Statistics Data
class Statistics {
  final int totalCourses;
  final int pendingAssignments;
  final int upcomingQuizzes;
  final double overallAverage;

  Statistics({
    required this.totalCourses,
    required this.pendingAssignments,
    required this.upcomingQuizzes,
    required this.overallAverage,
  });
}

/// Repository Providers
final assignmentRepositoryForDashboardProvider =
    Provider<IAssignmentRepository>((ref) {
      return AssignmentRepositoryImpl(
        remoteDataSource: AssignmentRemoteDataSourceImpl(),
      );
    });

final quizRepositoryForDashboardProvider = Provider<IQuizRepository>((ref) {
  return QuizRepositoryImpl(remoteDataSource: QuizRemoteDataSourceImpl());
});

final assignmentSubmissionRepositoryForDashboardProvider =
    Provider<IAssignmentSubmissionRepository>((ref) {
      return AssignmentSubmissionRepositoryImpl(
        remoteDatasource: AssignmentSubmissionRemoteDatasource(),
      );
    });

final quizAttemptRepositoryForDashboardProvider =
    Provider<IQuizAttemptRepository>((ref) {
      return QuizAttemptRepositoryImpl(
        remoteDatasource: QuizAttemptRemoteDatasource(),
      );
    });

final courseRepositoryForDashboardProvider = Provider<ICourseRepository>((ref) {
  return CourseRepositoryImpl(remoteDataSource: CourseRemoteDataSourceImpl());
});

final enrollmentRepositoryForDashboardProvider =
    Provider<IEnrollmentRepository>((ref) {
      return EnrollmentRepositoryImpl(
        remoteDataSource: EnrollmentRemoteDataSourceImpl(),
      );
    });

/// Student Dashboard Provider
final studentDashboardProvider =
    FutureProvider.family<StudentDashboardData, StudentDashboardParams>((
      ref,
      params,
    ) async {
      final assignmentRepo = ref.read(assignmentRepositoryForDashboardProvider);
      final quizRepo = ref.read(quizRepositoryForDashboardProvider);
      final submissionRepo = ref.read(
        assignmentSubmissionRepositoryForDashboardProvider,
      );
      final attemptRepo = ref.read(quizAttemptRepositoryForDashboardProvider);
      final courseRepo = ref.read(courseRepositoryForDashboardProvider);
      final enrollmentRepo = ref.read(enrollmentRepositoryForDashboardProvider);

      // Get student's courses
      final enrollments = await enrollmentRepo.getEnrollmentsByStudent(
        params.studentId,
        params.semesterId,
      );

      final courseIds = enrollments.map((e) => e.courseId).toList();
      if (courseIds.isEmpty) {
        return StudentDashboardData(
          upcomingAssignments: [],
          upcomingQuizzes: [],
          recentGrades: [],
          courseProgress: {},
          courseMap: {},
          statistics: Statistics(
            totalCourses: 0,
            pendingAssignments: 0,
            upcomingQuizzes: 0,
            overallAverage: 0.0,
          ),
        );
      }

      // Get all courses and create course map
      final courseMap = <String, CourseEntity>{};
      for (final courseId in courseIds) {
        final course = await courseRepo.getCourseById(courseId);
        if (course != null) {
          courseMap[courseId] = course;
        }
      }

      // Get all assignments and quizzes for student's courses
      final allAssignments = <AssignmentEntity>[];
      final allQuizzes = <QuizEntity>[];

      for (final courseId in courseIds) {
        final assignments = await assignmentRepo.getAssignmentsByCourse(
          courseId,
        );
        allAssignments.addAll(assignments);

        final quizzes = await quizRepo.getQuizzesByCourse(courseId);
        allQuizzes.addAll(quizzes);
      }

      // Get student's submissions and attempts
      final allSubmissions = await submissionRepo.getAllStudentSubmissions(
        params.studentId,
      );
      final allAttempts = await attemptRepo.getAllStudentAttempts(
        params.studentId,
      );

      // Filter upcoming assignments (deadline within next 7 days and not submitted)
      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));
      final submittedAssignmentIds = allSubmissions
          .map((s) => s.assignmentId)
          .toSet();

      final upcomingAssignments = allAssignments.where((assignment) {
        final isUpcoming =
            assignment.deadline.isAfter(now) &&
            assignment.deadline.isBefore(sevenDaysFromNow);
        final notSubmitted = !submittedAssignmentIds.contains(assignment.id);
        return isUpcoming && notSubmitted;
      }).toList()..sort((a, b) => a.deadline.compareTo(b.deadline));

      // Filter upcoming quizzes (opens within next 7 days or closes within next 7 days)
      final upcomingQuizzes = allQuizzes.where((quiz) {
        final opensSoon =
            quiz.timeOpen.isAfter(now) &&
            quiz.timeOpen.isBefore(sevenDaysFromNow);
        final closesSoon =
            quiz.timeClose.isAfter(now) &&
            quiz.timeClose.isBefore(sevenDaysFromNow);
        final isOpen = quiz.isOpen;
        return (opensSoon || closesSoon || isOpen) && !quiz.isClosed;
      }).toList()..sort((a, b) => a.timeOpen.compareTo(b.timeOpen));

      // Get recent grades (graded submissions from last 30 days)
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final recentGrades =
          allSubmissions
              .where(
                (s) =>
                    s.grade != null && s.submissionTime.isAfter(thirtyDaysAgo),
              )
              .toList()
            ..sort((a, b) => b.submissionTime.compareTo(a.submissionTime));

      // Calculate course progress
      final courseProgress = <String, CourseProgress>{};

      for (final courseId in courseIds) {
        final course = courseMap[courseId];
        if (course == null) continue;

        final courseAssignments = allAssignments
            .where((a) => a.courseId == courseId)
            .toList();
        final courseQuizzes = allQuizzes
            .where((q) => q.courseId == courseId)
            .toList();

        final courseSubmissions = allSubmissions
            .where((s) => s.courseId == courseId)
            .toList();
        final courseAttempts = allAttempts
            .where((a) => a.courseId == courseId)
            .toList();

        final submittedAssignmentIds = courseSubmissions
            .map((s) => s.assignmentId)
            .toSet();
        final completedQuizIds = courseAttempts
            .where((a) => a.isCompleted)
            .map((a) => a.quizId)
            .toSet();

        final gradedSubmissions = courseSubmissions
            .where((s) => s.grade != null)
            .toList();
        final averageGrade = gradedSubmissions.isEmpty
            ? 0.0
            : gradedSubmissions.map((s) => s.grade!).reduce((a, b) => a + b) /
                  gradedSubmissions.length;

        courseProgress[courseId] = CourseProgress(
          courseId: courseId,
          courseName: course.name,
          totalAssignments: courseAssignments.length,
          submittedAssignments: submittedAssignmentIds.length,
          totalQuizzes: courseQuizzes.length,
          completedQuizzes: completedQuizIds.length,
          averageGrade: averageGrade,
        );
      }

      // Calculate statistics
      final pendingAssignmentsCount = allAssignments
          .where(
            (a) =>
                !a.isClosed &&
                !submittedAssignmentIds.contains(a.id) &&
                a.deadline.isAfter(now),
          )
          .length;

      final upcomingQuizzesCount = upcomingQuizzes.length;

      final allGradedSubmissions = allSubmissions
          .where((s) => s.grade != null)
          .toList();
      final overallAverage = allGradedSubmissions.isEmpty
          ? 0.0
          : allGradedSubmissions.map((s) => s.grade!).reduce((a, b) => a + b) /
                allGradedSubmissions.length;

      final statistics = Statistics(
        totalCourses: courseIds.length,
        pendingAssignments: pendingAssignmentsCount,
        upcomingQuizzes: upcomingQuizzesCount,
        overallAverage: overallAverage,
      );

      return StudentDashboardData(
        upcomingAssignments: upcomingAssignments.take(5).toList(),
        upcomingQuizzes: upcomingQuizzes.take(5).toList(),
        recentGrades: recentGrades.take(10).toList(),
        courseProgress: courseProgress,
        courseMap: courseMap,
        statistics: statistics,
      );
    });

/// Parameters for student dashboard
class StudentDashboardParams {
  final String studentId;
  final String semesterId;

  StudentDashboardParams({required this.studentId, required this.semesterId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentDashboardParams &&
          runtimeType == other.runtimeType &&
          studentId == other.studentId &&
          semesterId == other.semesterId;

  @override
  int get hashCode => studentId.hashCode ^ semesterId.hashCode;
}
