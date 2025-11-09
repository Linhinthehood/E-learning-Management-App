import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/assignment_submission_entity.dart';
import '../../domain/entities/quiz_attempt_entity.dart';
import '../../domain/entities/view_tracking_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/entities/enrollment_entity.dart';

/// CSV Export Service for exporting tracking data to CSV format
class CsvExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Export assignment submissions to CSV
  /// 
  /// Returns CSV content as String
  /// Format: Student Name, Student Email, Status, Attempt Number, Grade, Submission Time, Files
  /// 
  /// Exports all enrolled students, including those who haven't submitted
  static String exportAssignmentSubmissions({
    required List<EnrollmentEntity> enrollments,
    required List<AssignmentSubmissionEntity> submissions,
    required Map<String, UserEntity> studentMap,
    required AssignmentEntity assignment,
  }) {
    final csvData = <List<dynamic>>[
      [
        'Student Name',
        'Student Email',
        'Status',
        'Attempt Number',
        'Grade',
        'Submission Time',
        'Files',
      ],
    ];

    // Create a map of studentId -> latest submission
    final submissionMap = <String, AssignmentSubmissionEntity>{};
    for (var submission in submissions) {
      final existing = submissionMap[submission.studentId];
      if (existing == null ||
          submission.attemptNumber > existing.attemptNumber) {
        submissionMap[submission.studentId] = submission;
      }
    }

    // Export all enrolled students
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final studentName = student?.displayName ?? 'Unknown';
      final studentEmail = student?.email ?? '';
      final submission = submissionMap[enrollment.studentId];

      // Determine status
      String status;
      int attemptNumber;
      String grade;
      String submissionTime;
      String files;

      if (submission == null) {
        status = 'Not Submitted';
        attemptNumber = 0;
        grade = 'N/A';
        submissionTime = 'N/A';
        files = 'N/A';
      } else {
        if (submission.isLate(assignment.deadline)) {
          status = 'Late';
        } else if (submission.grade != null) {
          status = 'Graded';
        } else {
          status = 'Submitted';
        }
        attemptNumber = submission.attemptNumber;
        grade = submission.grade?.toStringAsFixed(2) ?? 'N/A';
        submissionTime = _dateFormat.format(submission.submissionTime);
        files = submission.files.isEmpty
            ? 'No files'
            : submission.files.join('; ');
      }

      csvData.add([
        studentName,
        studentEmail,
        status,
        attemptNumber,
        grade,
        submissionTime,
        files,
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Export quiz attempts to CSV
  /// 
  /// Returns CSV content as String
  /// Format: Student Name, Student Email, Status, Score, Time Taken (minutes), Attempts, Completion Time
  /// 
  /// Exports all enrolled students, including those who haven't attempted
  static String exportQuizResults({
    required List<EnrollmentEntity> enrollments,
    required List<QuizAttemptEntity> attempts,
    required Map<String, UserEntity> studentMap,
    required double maxScore,
  }) {
    final csvData = <List<dynamic>>[
      [
        'Student Name',
        'Student Email',
        'Status',
        'Score',
        'Max Score',
        'Percentage',
        'Time Taken (minutes)',
        'Attempt Number',
        'Completion Time',
      ],
    ];

    // Create a map of studentId -> best attempt (highest score)
    final attemptMap = <String, QuizAttemptEntity>{};
    for (var attempt in attempts) {
      if (attempt.isCompleted) {
        final existing = attemptMap[attempt.studentId];
        if (existing == null ||
            (attempt.score ?? 0) > (existing.score ?? 0)) {
          attemptMap[attempt.studentId] = attempt;
        }
      }
    }

    // Export all enrolled students
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final studentName = student?.displayName ?? 'Unknown';
      final studentEmail = student?.email ?? '';
      final attempt = attemptMap[enrollment.studentId];

      // Determine status
      String status;
      String score;
      String maxScoreStr;
      String percentage;
      String timeTaken;
      int attemptNumber;
      String completionTime;

      if (attempt == null) {
        status = 'Not Started';
        score = 'N/A';
        maxScoreStr = maxScore.toStringAsFixed(2);
        percentage = 'N/A';
        timeTaken = 'N/A';
        attemptNumber = 0;
        completionTime = 'N/A';
      } else {
        if (attempt.status == QuizAttemptStatus.graded) {
          status = 'Graded';
        } else if (attempt.status == QuizAttemptStatus.submitted) {
          status = 'Submitted';
        } else {
          status = 'In Progress';
        }
        score = attempt.score?.toStringAsFixed(2) ?? 'N/A';
        maxScoreStr = attempt.maxScore.toStringAsFixed(2);
        percentage = attempt.percentage?.toStringAsFixed(2) ?? 'N/A';
        timeTaken = attempt.durationMinutes?.toString() ?? 'N/A';
        attemptNumber = attempt.attemptNumber;
        completionTime = attempt.endTime != null
            ? _dateFormat.format(attempt.endTime!)
            : 'N/A';
      }

      csvData.add([
        studentName,
        studentEmail,
        status,
        score,
        maxScoreStr,
        percentage,
        timeTaken,
        attemptNumber,
        completionTime,
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Export announcement views to CSV
  /// 
  /// Returns CSV content as String
  /// Format: Student Name, Student Email, Action, Viewed At
  /// 
  /// Exports all enrolled students, including those who haven't viewed
  static String exportAnnouncementViews({
    required List<EnrollmentEntity> enrollments,
    required List<ViewTrackingEntity> views,
    required Map<String, UserEntity> studentMap,
  }) {
    final csvData = <List<dynamic>>[
      [
        'Student Name',
        'Student Email',
        'Action',
        'Viewed At',
      ],
    ];

    // Create a map of studentId -> view tracking (latest view)
    final viewMap = <String, ViewTrackingEntity>{};
    for (var view in views) {
      if (view.isView) {
        final existing = viewMap[view.studentId];
        if (existing == null ||
            view.timestamp.isAfter(existing.timestamp)) {
          viewMap[view.studentId] = view;
        }
      }
    }

    // Export all enrolled students
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final studentName = student?.displayName ?? 'Unknown';
      final studentEmail = student?.email ?? '';
      final view = viewMap[enrollment.studentId];

      if (view != null) {
        final viewedAt = _dateFormat.format(view.timestamp);
        csvData.add([
          studentName,
          studentEmail,
          'Viewed',
          viewedAt,
        ]);
      } else {
        csvData.add([
          studentName,
          studentEmail,
          'Not Viewed',
          'N/A',
        ]);
      }
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Export material downloads to CSV
  /// 
  /// Returns CSV content as String
  /// Format: Student Name, Student Email, Action, Downloaded At
  /// 
  /// Exports all enrolled students, including those who haven't downloaded
  static String exportMaterialDownloads({
    required List<EnrollmentEntity> enrollments,
    required List<ViewTrackingEntity> downloads,
    required Map<String, UserEntity> studentMap,
  }) {
    final csvData = <List<dynamic>>[
      [
        'Student Name',
        'Student Email',
        'Action',
        'Downloaded At',
      ],
    ];

    // Create a map of studentId -> download tracking (latest download)
    final downloadMap = <String, ViewTrackingEntity>{};
    for (var download in downloads) {
      if (download.isDownload) {
        final existing = downloadMap[download.studentId];
        if (existing == null ||
            download.timestamp.isAfter(existing.timestamp)) {
          downloadMap[download.studentId] = download;
        }
      }
    }

    // Export all enrolled students
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final studentName = student?.displayName ?? 'Unknown';
      final studentEmail = student?.email ?? '';
      final download = downloadMap[enrollment.studentId];

      if (download != null) {
        final downloadedAt = _dateFormat.format(download.timestamp);
        csvData.add([
          studentName,
          studentEmail,
          'Downloaded',
          downloadedAt,
        ]);
      } else {
        csvData.add([
          studentName,
          studentEmail,
          'Not Downloaded',
          'N/A',
        ]);
      }
    }

    return const ListToCsvConverter().convert(csvData);
  }
}

