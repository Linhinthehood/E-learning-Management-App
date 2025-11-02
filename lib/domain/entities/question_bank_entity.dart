/// Question bank entity for organizing quiz questions
class QuestionBankEntity {
  final String id;
  final String courseId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const QuestionBankEntity({
    required this.id,
    required this.courseId,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if question bank has description
  bool get hasDescription => description != null && description!.isNotEmpty;

  /// Check if question bank was updated
  bool get wasUpdated => updatedAt != null;
}
