import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/quiz_entity.dart';
import '../../domain/entities/assignment_submission_entity.dart';
import '../../domain/entities/quiz_attempt_entity.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/entities/forum_topic_entity.dart';
import '../../domain/repositories/i_assignment_repository.dart';
import '../../domain/repositories/i_quiz_repository.dart';
import '../../domain/repositories/i_assignment_submission_repository.dart';
import '../../domain/repositories/i_quiz_attempt_repository.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../../domain/repositories/i_enrollment_repository.dart';
import '../../domain/repositories/i_forum_topic_repository.dart';
import '../../data/repositories/assignment_repository_impl.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../data/repositories/assignment_submission_repository_impl.dart';
import '../../data/repositories/quiz_attempt_repository_impl.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/repositories/enrollment_repository_impl.dart';
import '../../data/repositories/forum_topic_repository_impl.dart';
import '../../data/datasources/remote/assignment_remote_datasource.dart';
import '../../data/datasources/remote/quiz_remote_datasource.dart';
import '../../data/datasources/remote/assignment_submission_remote_datasource.dart';
import '../../data/datasources/remote/quiz_attempt_remote_datasource.dart';
import '../../data/datasources/remote/course_remote_datasource.dart';
import '../../data/datasources/remote/enrollment_remote_datasource.dart';
import '../../data/datasources/remote/forum_topic_remote_datasource.dart';
import '../../data/datasources/models/course_model.dart';
import '../../data/datasources/models/user_model.dart';

/// Instructor Dashboard Data Model
class InstructorDashboardData {
  final List<RecentActivity> recentActivities;
  final InstructorStatistics statistics;
  final Map<String, CourseEntity> courseMap;
  final List<AssignmentSubmissionData> submissionChartData;
  final List<QuizScoreData> quizScoreChartData;

  InstructorDashboardData({
    required this.recentActivities,
    required this.statistics,
    required this.courseMap,
    required this.submissionChartData,
    required this.quizScoreChartData,
  });
}

/// Data for submission rate chart
class AssignmentSubmissionData {
  final String assignmentTitle;
  final int totalStudents;
  final int submitted;

  AssignmentSubmissionData({
    required this.assignmentTitle,
    required this.totalStudents,
    required this.submitted,
  });

  double get submissionRate =>
      totalStudents > 0 ? (submitted / totalStudents) * 100 : 0;
}

/// Data for quiz score chart
class QuizScoreData {
  final String quizTitle;
  final double averageScore;
  final int attempts;

  QuizScoreData({
    required this.quizTitle,
    required this.averageScore,
    required this.attempts,
  });
}

/// Recent Activity (submissions, quiz completions, forum posts)
class RecentActivity {
  final String id;
  final String type; // 'submission', 'quiz', 'forum'
  final String studentName;
  final String courseName;
  final String courseId;
  final String title;
  final DateTime timestamp;
  final String? grade;
  final String relatedId; // assignment/quiz/topic ID

  RecentActivity({
    required this.id,
    required this.type,
    required this.studentName,
    required this.courseName,
    required this.courseId,
    required this.title,
    required this.timestamp,
    this.grade,
    required this.relatedId,
  });
}

/// Instructor Statistics Data
class InstructorStatistics {
  final int totalCourses;
  final int totalStudents;
  final int totalAssignments;
  final int totalQuizzes;
  final double averageSubmissionRate;
  final double averageQuizScore;

  InstructorStatistics({
    required this.totalCourses,
    required this.totalStudents,
    required this.totalAssignments,
    required this.totalQuizzes,
    required this.averageSubmissionRate,
    required this.averageQuizScore,
  });
}

/// Repository Providers
final assignmentRepositoryForInstructorDashboardProvider =
    Provider<IAssignmentRepository>((ref) {
      return AssignmentRepositoryImpl(
        remoteDataSource: AssignmentRemoteDataSourceImpl(),
      );
    });

final quizRepositoryForInstructorDashboardProvider = Provider<IQuizRepository>((
  ref,
) {
  return QuizRepositoryImpl(remoteDataSource: QuizRemoteDataSourceImpl());
});

final assignmentSubmissionRepositoryForInstructorDashboardProvider =
    Provider<IAssignmentSubmissionRepository>((ref) {
      return AssignmentSubmissionRepositoryImpl(
        remoteDatasource: AssignmentSubmissionRemoteDatasource(),
      );
    });

final quizAttemptRepositoryForInstructorDashboardProvider =
    Provider<IQuizAttemptRepository>((ref) {
      return QuizAttemptRepositoryImpl(
        remoteDatasource: QuizAttemptRemoteDatasource(),
      );
    });

final courseRepositoryForInstructorDashboardProvider =
    Provider<ICourseRepository>((ref) {
      return CourseRepositoryImpl(
        remoteDataSource: CourseRemoteDataSourceImpl(),
      );
    });

final enrollmentRepositoryForInstructorDashboardProvider =
    Provider<IEnrollmentRepository>((ref) {
      return EnrollmentRepositoryImpl(
        remoteDataSource: EnrollmentRemoteDataSourceImpl(),
      );
    });

final forumTopicRepositoryForInstructorDashboardProvider =
    Provider<IForumTopicRepository>((ref) {
      return ForumTopicRepositoryImpl(
        remoteDataSource: ForumTopicRemoteDataSourceImpl(),
      );
    });

/// Instructor Dashboard Provider
final instructorDashboardProvider =
    FutureProvider.family<InstructorDashboardData, String>((
      ref,
      instructorId,
    ) async {
      final assignmentRepo = ref.read(
        assignmentRepositoryForInstructorDashboardProvider,
      );
      final quizRepo = ref.read(quizRepositoryForInstructorDashboardProvider);
      final submissionRepo = ref.read(
        assignmentSubmissionRepositoryForInstructorDashboardProvider,
      );
      final attemptRepo = ref.read(
        quizAttemptRepositoryForInstructorDashboardProvider,
      );
      final enrollmentRepo = ref.read(
        enrollmentRepositoryForInstructorDashboardProvider,
      );
      final forumTopicRepo = ref.read(
        forumTopicRepositoryForInstructorDashboardProvider,
      );

      // Get instructor's courses by querying Firestore directly
      final firestore = FirebaseFirestore.instance;
      final coursesSnapshot = await firestore
          .collection('courses')
          .where('instructorId', isEqualTo: instructorId)
          .get();

      final allCourses = coursesSnapshot.docs
          .map((doc) => CourseModel.fromJson(doc.data(), doc.id).toEntity())
          .toList();
      final courseIds = allCourses.map((c) => c.id).toList();

      if (courseIds.isEmpty) {
        return InstructorDashboardData(
          recentActivities: [],
          statistics: InstructorStatistics(
            totalCourses: 0,
            totalStudents: 0,
            totalAssignments: 0,
            totalQuizzes: 0,
            averageSubmissionRate: 0.0,
            averageQuizScore: 0.0,
          ),
          courseMap: {},
          submissionChartData: [],
          quizScoreChartData: [],
        );
      }

      // Create course map
      final courseMap = <String, CourseEntity>{};
      for (final course in allCourses) {
        courseMap[course.id] = course;
      }

      // Get all assignments and quizzes for instructor's courses
      final allAssignments = <AssignmentEntity>[];
      final allQuizzes = <QuizEntity>[];
      final allSubmissions = <AssignmentSubmissionEntity>[];
      final allAttempts = <QuizAttemptEntity>[];
      final allForumTopics = <ForumTopicEntity>[];
      final allEnrollments = <String>[]; // student IDs

      for (final courseId in courseIds) {
        final assignments = await assignmentRepo.getAssignmentsByCourse(
          courseId,
        );
        allAssignments.addAll(assignments);

        final quizzes = await quizRepo.getQuizzesByCourse(courseId);
        allQuizzes.addAll(quizzes);

        // Get submissions for all assignments in this course
        for (final assignment in assignments) {
          final submissions = await submissionRepo.getSubmissionsByAssignment(
            assignment.id,
          );
          allSubmissions.addAll(submissions);
        }

        // Get attempts for all quizzes in this course
        for (final quiz in quizzes) {
          final attempts = await attemptRepo.getAttemptsByQuiz(quiz.id);
          allAttempts.addAll(attempts);
        }

        final topics = await forumTopicRepo.getTopicsByCourse(courseId);
        allForumTopics.addAll(topics);

        final enrollments = await enrollmentRepo.getEnrollmentsByCourse(
          courseId,
        );
        for (final enrollment in enrollments) {
          if (!allEnrollments.contains(enrollment.studentId)) {
            allEnrollments.add(enrollment.studentId);
          }
        }
      }

      // Calculate statistics
      final totalCourses = allCourses.length;
      final totalStudents = allEnrollments.length;
      final totalAssignments = allAssignments.length;
      final totalQuizzes = allQuizzes.length;

      // Calculate average submission rate
      final totalPossibleSubmissions = totalAssignments * totalStudents;
      final averageSubmissionRate = totalPossibleSubmissions == 0
          ? 0.0
          : (allSubmissions.length / totalPossibleSubmissions) * 100;

      // Calculate average quiz score
      final gradedAttempts = allAttempts.where((a) => a.score != null).toList();
      final averageQuizScore = gradedAttempts.isEmpty
          ? 0.0
          : gradedAttempts
                    .map((a) => a.percentage ?? 0.0)
                    .reduce((a, b) => a + b) /
                gradedAttempts.length;

      final statistics = InstructorStatistics(
        totalCourses: totalCourses,
        totalStudents: totalStudents,
        totalAssignments: totalAssignments,
        totalQuizzes: totalQuizzes,
        averageSubmissionRate: averageSubmissionRate,
        averageQuizScore: averageQuizScore,
      );

      // Build recent activities (last 10)
      final recentActivities = <RecentActivity>[];

      // Get user cache for names
      final userCache = <String, String>{};

      // Helper function to get user name
      Future<String> getUserName(String userId) async {
        if (userCache.containsKey(userId)) {
          return userCache[userId]!;
        }
        try {
          final userDoc = await firestore.collection('users').doc(userId).get();
          if (userDoc.exists && userDoc.data() != null) {
            final userData = UserModel.fromJson(userDoc.data()!);
            userCache[userId] = userData.displayName;
            return userData.displayName;
          }
        } catch (e) {
          // Ignore errors
        }
        return 'Unknown User';
      }

      // Add recent submissions
      for (final submission in allSubmissions) {
        final assignment = allAssignments
            .where((a) => a.id == submission.assignmentId)
            .firstOrNull;
        if (assignment == null) continue;

        final course = courseMap[submission.courseId];
        if (course == null) continue;

        final studentName = await getUserName(submission.studentId);

        recentActivities.add(
          RecentActivity(
            id: submission.id,
            type: 'submission',
            studentName: studentName,
            courseName: course.name,
            courseId: course.id,
            title: assignment.title,
            timestamp: submission.submissionTime,
            grade: submission.grade?.toStringAsFixed(1),
            relatedId: submission.assignmentId,
          ),
        );
      }

      // Add recent quiz attempts
      for (final attempt in allAttempts.where((a) => a.isCompleted)) {
        final quiz = allQuizzes
            .where((q) => q.id == attempt.quizId)
            .firstOrNull;
        if (quiz == null) continue;

        final course = courseMap[attempt.courseId];
        if (course == null) continue;

        final studentName = await getUserName(attempt.studentId);

        recentActivities.add(
          RecentActivity(
            id: attempt.id,
            type: 'quiz',
            studentName: studentName,
            courseName: course.name,
            courseId: course.id,
            title: quiz.title,
            timestamp: attempt.endTime ?? attempt.startTime,
            grade: attempt.score?.toStringAsFixed(1),
            relatedId: attempt.quizId,
          ),
        );
      }

      // Add recent forum topics
      for (final topic in allForumTopics) {
        final course = courseMap[topic.courseId];
        if (course == null) continue;

        final authorName = await getUserName(topic.authorId);

        recentActivities.add(
          RecentActivity(
            id: topic.id,
            type: 'forum',
            studentName: authorName,
            courseName: course.name,
            courseId: course.id,
            title: topic.title,
            timestamp: topic.createdAt,
            relatedId: topic.id,
          ),
        );
      }

      // Sort by timestamp (newest first) and take top 10
      recentActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Build chart data for assignments (top 8 by submission count)
      final submissionChartData = <AssignmentSubmissionData>[];
      for (final assignment in allAssignments) {
        final assignmentSubmissions = allSubmissions
            .where((s) => s.assignmentId == assignment.id)
            .length;
        submissionChartData.add(
          AssignmentSubmissionData(
            assignmentTitle: assignment.title.length > 15
                ? '${assignment.title.substring(0, 15)}...'
                : assignment.title,
            totalStudents: totalStudents,
            submitted: assignmentSubmissions,
          ),
        );
      }
      // Sort by submission count and take top 8
      submissionChartData.sort((a, b) => b.submitted.compareTo(a.submitted));
      final topSubmissionData = submissionChartData.take(8).toList();

      // Build chart data for quizzes (top 8 by average score)
      final quizChartData = <QuizScoreData>[];
      for (final quiz in allQuizzes) {
        final quizAttempts = allAttempts
            .where((a) => a.quizId == quiz.id)
            .toList();
        final completedAttempts = quizAttempts
            .where((a) => a.isCompleted && a.score != null)
            .toList();
        if (completedAttempts.isNotEmpty) {
          final avgScore =
              completedAttempts
                  .map((a) => a.percentage ?? 0.0)
                  .reduce((a, b) => a + b) /
              completedAttempts.length;
          quizChartData.add(
            QuizScoreData(
              quizTitle: quiz.title.length > 15
                  ? '${quiz.title.substring(0, 15)}...'
                  : quiz.title,
              averageScore: avgScore,
              attempts: completedAttempts.length,
            ),
          );
        }
      }
      // Sort by average score and take top 8
      quizChartData.sort((a, b) => b.averageScore.compareTo(a.averageScore));
      final topQuizData = quizChartData.take(8).toList();

      return InstructorDashboardData(
        recentActivities: recentActivities.take(10).toList(),
        statistics: statistics,
        courseMap: courseMap,
        submissionChartData: topSubmissionData,
        quizScoreChartData: topQuizData,
      );
    });

/// Navigation result base class for activity items
abstract class ActivityNavigationResult {}

class AssignmentActivityNavigationResult extends ActivityNavigationResult {
  final CourseEntity course;
  final AssignmentEntity assignment;

  AssignmentActivityNavigationResult({
    required this.course,
    required this.assignment,
  });
}

class QuizActivityNavigationResult extends ActivityNavigationResult {
  final CourseEntity course;
  final QuizEntity quiz;

  QuizActivityNavigationResult({required this.course, required this.quiz});
}

class ForumActivityNavigationResult extends ActivityNavigationResult {
  final CourseEntity course;
  final String topicId;

  ForumActivityNavigationResult({required this.course, required this.topicId});
}

/// Service that converts RecentActivity to navigation targets
class ActivityNavigationService {
  ActivityNavigationService({
    required IAssignmentRepository assignmentRepository,
    required IQuizRepository quizRepository,
    required IForumTopicRepository forumTopicRepository,
  }) : _assignmentRepository = assignmentRepository,
       _quizRepository = quizRepository,
       _forumTopicRepository = forumTopicRepository;

  final IAssignmentRepository _assignmentRepository;
  final IQuizRepository _quizRepository;
  final IForumTopicRepository _forumTopicRepository;

  Future<ActivityNavigationResult?> resolve(
    RecentActivity activity,
    Map<String, CourseEntity> courseMap,
  ) async {
    final course = courseMap[activity.courseId];
    if (course == null) return null;

    switch (activity.type) {
      case 'submission':
        final assignment = await _assignmentRepository.getAssignmentById(
          activity.relatedId,
        );
        if (assignment == null) return null;
        return AssignmentActivityNavigationResult(
          course: course,
          assignment: assignment,
        );

      case 'quiz':
        final quiz = await _quizRepository.getQuizById(activity.relatedId);
        if (quiz == null) return null;
        return QuizActivityNavigationResult(course: course, quiz: quiz);

      case 'forum':
        // Verify topic exists
        final topic = await _forumTopicRepository.getTopicById(
          activity.relatedId,
        );
        if (topic == null) return null;
        return ForumActivityNavigationResult(
          course: course,
          topicId: activity.relatedId,
        );

      default:
        return null;
    }
  }
}

/// Provider exposing navigation resolver for activities
final activityNavigationServiceProvider = Provider<ActivityNavigationService>((
  ref,
) {
  return ActivityNavigationService(
    assignmentRepository: ref.read(
      assignmentRepositoryForInstructorDashboardProvider,
    ),
    quizRepository: ref.read(quizRepositoryForInstructorDashboardProvider),
    forumTopicRepository: ref.read(
      forumTopicRepositoryForInstructorDashboardProvider,
    ),
  );
});
