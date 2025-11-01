import '../../../domain/entities/semester_entity.dart';

/// Data model for Semester
/// Handles conversion between JSON and Entity
class SemesterModel {
  final String id;
  final String name;
  final String code;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  SemesterModel({
    required this.id,
    required this.name,
    required this.code,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  /// Convert from JSON
  factory SemesterModel.fromJson(Map<String, dynamic> json) {
    return SemesterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to Entity
  SemesterEntity toEntity() {
    return SemesterEntity(
      id: id,
      name: name,
      code: code,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
    );
  }

  /// Convert from Entity
  factory SemesterModel.fromEntity(SemesterEntity entity) {
    return SemesterModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      startDate: entity.startDate,
      endDate: entity.endDate,
      createdAt: entity.createdAt,
    );
  }
}
