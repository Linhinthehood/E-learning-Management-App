import '../../../domain/entities/material_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Material
/// Used to convert between API/Database format and Entity
class MaterialModel {
  final String id;
  final String title;
  final String description;
  final List<MaterialFile> files;
  final String courseId;
  final List<String> scopedGroupIds;
  final MaterialType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MaterialModel({
    required this.id,
    required this.title,
    required this.description,
    required this.files,
    required this.courseId,
    required this.scopedGroupIds,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert from JSON (Firestore document)
  factory MaterialModel.fromJson(Map<String, dynamic> json, String id) {
    return MaterialModel(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String,
      files: (json['files'] as List<dynamic>)
          .map((f) => _materialFileFromJson(f as Map<String, dynamic>))
          .toList(),
      courseId: json['courseId'] as String,
      scopedGroupIds: List<String>.from(json['scopedGroupIds'] ?? []),
      type: MaterialType.values.byName(json['type'] as String),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'files': files.map(_materialFileToJson).toList(),
      'courseId': courseId,
      'scopedGroupIds': scopedGroupIds,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Convert to Entity (domain layer)
  MaterialEntity toEntity() {
    return MaterialEntity(
      id: id,
      title: title,
      description: description,
      files: files,
      courseId: courseId,
      scopedGroupIds: scopedGroupIds,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert from Entity (domain layer)
  factory MaterialModel.fromEntity(MaterialEntity entity) {
    return MaterialModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      files: entity.files,
      courseId: entity.courseId,
      scopedGroupIds: entity.scopedGroupIds,
      type: entity.type,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // Helper methods for MaterialFile serialization

  static MaterialFile _materialFileFromJson(Map<String, dynamic> json) {
    return MaterialFile(
      name: json['name'] as String,
      url: json['url'] as String,
      type: MaterialFileType.values.byName(json['type'] as String),
      fileSizeBytes: json['fileSizeBytes'] as int?,
    );
  }

  static Map<String, dynamic> _materialFileToJson(MaterialFile file) {
    return {
      'name': file.name,
      'url': file.url,
      'type': file.type.name,
      if (file.fileSizeBytes != null) 'fileSizeBytes': file.fileSizeBytes,
    };
  }
}
