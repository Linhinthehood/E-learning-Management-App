import '../../../domain/entities/quiz_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Quiz
/// Used to convert between API/Database format and Entity
class QuizModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final DateTime timeOpen;
  final DateTime timeClose;
  final int durationMinutes;
  final int numAttempts;
  final QuizStructure structure;
  final List<String> scopedGroupIds;
  final bool shuffleQuestions;
  final bool shuffleAnswers;
  final DateTime createdAt;

  QuizModel({
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

  /// Convert from JSON (Firestore document)
  factory QuizModel.fromJson(Map<String, dynamic> json, String id) {
    return QuizModel(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String,
      courseId: json['courseId'] as String,
      timeOpen: (json['timeOpen'] as Timestamp).toDate(),
      timeClose: (json['timeClose'] as Timestamp).toDate(),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      numAttempts: json['numAttempts'] as int? ?? 1,
      structure: _quizStructureFromJson(
        json['structure'] as Map<String, dynamic>,
      ),
      scopedGroupIds: List<String>.from(json['scopedGroupIds'] ?? []),
      shuffleQuestions: json['shuffleQuestions'] as bool? ?? false,
      shuffleAnswers: json['shuffleAnswers'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'courseId': courseId,
      'timeOpen': Timestamp.fromDate(timeOpen),
      'timeClose': Timestamp.fromDate(timeClose),
      'durationMinutes': durationMinutes,
      'numAttempts': numAttempts,
      'structure': _quizStructureToJson(structure),
      'scopedGroupIds': scopedGroupIds,
      'shuffleQuestions': shuffleQuestions,
      'shuffleAnswers': shuffleAnswers,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert to Entity (domain layer)
  QuizEntity toEntity() {
    return QuizEntity(
      id: id,
      title: title,
      description: description,
      courseId: courseId,
      timeOpen: timeOpen,
      timeClose: timeClose,
      durationMinutes: durationMinutes,
      numAttempts: numAttempts,
      structure: structure,
      scopedGroupIds: scopedGroupIds,
      shuffleQuestions: shuffleQuestions,
      shuffleAnswers: shuffleAnswers,
      createdAt: createdAt,
    );
  }

  /// Convert from Entity (domain layer)
  factory QuizModel.fromEntity(QuizEntity entity) {
    return QuizModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      courseId: entity.courseId,
      timeOpen: entity.timeOpen,
      timeClose: entity.timeClose,
      durationMinutes: entity.durationMinutes,
      numAttempts: entity.numAttempts,
      structure: entity.structure,
      scopedGroupIds: entity.scopedGroupIds,
      shuffleQuestions: entity.shuffleQuestions,
      shuffleAnswers: entity.shuffleAnswers,
      createdAt: entity.createdAt,
    );
  }

  // Helper methods for nested QuizStructure serialization

  static QuizStructure _quizStructureFromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>;
    final sections = sectionsJson
        .map((s) => _quizSectionFromJson(s as Map<String, dynamic>))
        .toList();
    return QuizStructure(sections: sections);
  }

  static Map<String, dynamic> _quizStructureToJson(QuizStructure structure) {
    return {'sections': structure.sections.map(_quizSectionToJson).toList()};
  }

  static QuizSection _quizSectionFromJson(Map<String, dynamic> json) {
    return QuizSection(
      name: json['name'] as String,
      numQuestions: json['numQuestions'] as int,
      questionBankId: json['questionBankId'] as String?,
      specificQuestionIds: json['specificQuestionIds'] != null
          ? List<String>.from(json['specificQuestionIds'])
          : null,
    );
  }

  static Map<String, dynamic> _quizSectionToJson(QuizSection section) {
    return {
      'name': section.name,
      'numQuestions': section.numQuestions,
      if (section.questionBankId != null)
        'questionBankId': section.questionBankId,
      if (section.specificQuestionIds != null)
        'specificQuestionIds': section.specificQuestionIds,
    };
  }
}
