import '../entities/material_entity.dart';

/// Material repository interface
/// This defines the contract that data layer must implement
abstract class IMaterialRepository {
  /// Get all materials for a course
  Future<List<MaterialEntity>> getMaterialsByCourse(String courseId);

  /// Get materials for a specific group
  Future<List<MaterialEntity>> getMaterialsByGroup(
    String courseId,
    String groupId,
  );

  /// Get a single material by ID
  Future<MaterialEntity?> getMaterialById(String materialId);

  /// Get materials by type
  Future<List<MaterialEntity>> getMaterialsByType(
    String courseId,
    MaterialType type,
  );

  /// Create a new material
  Future<MaterialEntity> createMaterial(MaterialEntity material);

  /// Update an existing material
  Future<MaterialEntity> updateMaterial(MaterialEntity material);

  /// Delete a material
  Future<void> deleteMaterial(String materialId);

  /// Upload a file and get URL
  Future<String> uploadFile(String filePath, String fileName);
}
