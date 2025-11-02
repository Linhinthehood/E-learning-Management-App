/// Question entity for quiz questions
class QuestionEntity {
  final String id;
  final String questionBankId; // Which question bank this belongs to
  final String questionText;
  final QuestionType type;
  final List<String> options; // Answer choices
  final dynamic correctAnswer; // Index for multiple choice, text for others
  final QuestionDifficulty difficulty;
  final double points; // Points awarded for correct answer
  final String? explanation; // Explanation shown after answering
  final String? imageUrl; // Optional image for the question
  final DateTime createdAt;

  const QuestionEntity({
    required this.id,
    required this.questionBankId,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    required this.points,
    this.explanation,
    this.imageUrl,
    required this.createdAt,
  });

  /// Check if question has explanation
  bool get hasExplanation => explanation != null && explanation!.isNotEmpty;

  /// Check if question has image
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// Get correct answer index (for multiple choice)
  int? get correctAnswerIndex {
    if (type == QuestionType.multipleChoice && correctAnswer is int) {
      return correctAnswer as int;
    }
    return null;
  }

  /// Get correct answer text (for true/false, short answer)
  String? get correctAnswerText {
    if (correctAnswer is String) {
      return correctAnswer as String;
    }
    return null;
  }

  /// Get difficulty color
  String get difficultyColor {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'green';
      case QuestionDifficulty.medium:
        return 'orange';
      case QuestionDifficulty.hard:
        return 'red';
    }
  }
}

/// Type of question
enum QuestionType {
  multipleChoice, // Single correct answer from options
  trueFalse, // True or False question
  shortAnswer, // Text-based answer
  multipleResponse, // Multiple correct answers
}

/// Difficulty level
enum QuestionDifficulty {
  easy,
  medium,
  hard,
}
