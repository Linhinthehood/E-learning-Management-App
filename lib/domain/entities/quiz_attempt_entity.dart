/// Quiz attempt entity for tracking student quiz submissions
class QuizAttemptEntity {
  final String id;
  final String quizId;
  final String studentId;
  final String courseId;
  final int attemptNumber;
  final DateTime startTime;
  final DateTime? endTime; // null if still in progress
  final Map<String, dynamic> answers; // questionId -> student's answer
  final double? score; // Final score (null if not graded)
  final double maxScore; // Maximum possible score
  final QuizAttemptStatus status;
  final String? feedback; // Optional instructor feedback
  final bool autoGraded; // True if automatically graded

  const QuizAttemptEntity({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.courseId,
    required this.attemptNumber,
    required this.startTime,
    this.endTime,
    required this.answers,
    this.score,
    required this.maxScore,
    required this.status,
    this.feedback,
    required this.autoGraded,
  });

  /// Check if attempt is completed
  bool get isCompleted => endTime != null;

  /// Check if attempt is in progress
  bool get isInProgress => status == QuizAttemptStatus.inProgress;

  /// Check if attempt is graded
  bool get isGraded => status == QuizAttemptStatus.graded;

  /// Get percentage score
  double? get percentage {
    if (score == null || maxScore == 0) return null;
    return (score! / maxScore) * 100;
  }

  /// Get duration in minutes
  int? get durationMinutes {
    if (endTime == null) return null;
    return endTime!.difference(startTime).inMinutes;
  }

  /// Get number of answered questions
  int get answeredCount => answers.length;

  /// Copy with method for updating
  QuizAttemptEntity copyWith({
    String? id,
    String? quizId,
    String? studentId,
    String? courseId,
    int? attemptNumber,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? answers,
    double? score,
    double? maxScore,
    QuizAttemptStatus? status,
    String? feedback,
    bool? autoGraded,
  }) {
    return QuizAttemptEntity(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      status: status ?? this.status,
      feedback: feedback ?? this.feedback,
      autoGraded: autoGraded ?? this.autoGraded,
    );
  }
}

/// Status of a quiz attempt
enum QuizAttemptStatus {
  inProgress, // Student is currently taking the quiz
  submitted, // Student submitted but not graded yet
  graded, // Quiz has been graded
}
