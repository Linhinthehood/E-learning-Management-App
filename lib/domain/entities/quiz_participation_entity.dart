/// Quiz participation entity for tracking active quiz participants
/// Used for real-time participant counters
class QuizParticipationEntity {
  final String id; // Document ID (format: quizId_studentId)
  final String quizId;
  final String studentId;
  final DateTime joinedAt;
  final bool isActive; // Currently taking the quiz

  const QuizParticipationEntity({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.joinedAt,
    this.isActive = true,
  });
}
