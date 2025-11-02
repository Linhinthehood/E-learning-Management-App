/// Quiz entity for course quizzes/tests
class QuizEntity {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final DateTime timeOpen; // When quiz becomes available
  final DateTime timeClose; // When quiz closes
  final int durationMinutes; // Time limit in minutes (0 = no limit)
  final int numAttempts; // Number of allowed attempts (0 = unlimited)
  final QuizStructure structure;
  final List<String> scopedGroupIds; // Empty = all groups
  final bool shuffleQuestions; // Randomize question order
  final bool shuffleAnswers; // Randomize answer order
  final DateTime createdAt;

  const QuizEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.timeOpen,
    required this.timeClose,
    required this.durationMinutes,
    required this.numAttempts,
    required this.structure,
    required this.scopedGroupIds,
    required this.shuffleQuestions,
    required this.shuffleAnswers,
    required this.createdAt,
  });

  /// Check if quiz is for all groups
  bool get isForAllGroups => scopedGroupIds.isEmpty;

  /// Check if quiz has time limit
  bool get hasTimeLimit => durationMinutes > 0;

  /// Check if quiz has unlimited attempts
  bool get hasUnlimitedAttempts => numAttempts == 0;

  /// Check if quiz is currently open
  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(timeOpen) && now.isBefore(timeClose);
  }

  /// Check if quiz is closed
  bool get isClosed => DateTime.now().isAfter(timeClose);

  /// Check if quiz is upcoming
  bool get isUpcoming => DateTime.now().isBefore(timeOpen);
}

/// Quiz structure (how questions are organized)
class QuizStructure {
  final List<QuizSection> sections;

  const QuizStructure({required this.sections});

  /// Get total number of questions
  int get totalQuestions {
    return sections.fold(0, (sum, section) => sum + section.numQuestions);
  }
}

/// A section in the quiz (can pull from question bank or have specific questions)
class QuizSection {
  final String name;
  final int numQuestions; // Number of questions to show
  final String? questionBankId; // Pull from question bank if specified
  final List<String>? specificQuestionIds; // Or use specific questions

  const QuizSection({
    required this.name,
    required this.numQuestions,
    this.questionBankId,
    this.specificQuestionIds,
  });

  /// Check if section uses question bank
  bool get usesQuestionBank => questionBankId != null;

  /// Check if section uses specific questions
  bool get usesSpecificQuestions => specificQuestionIds != null;
}
