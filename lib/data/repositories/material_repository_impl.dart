import '../../domain/entities/material_entity.dart';
import '../../domain/repositories/i_material_repository.dart';
import '../datasources/remote/material_remote_datasource.dart';
import '../datasources/models/material_model.dart';

/// Implementation of IMaterialRepository
/// Handles conversion between models and entities
class MaterialRepositoryImpl implements IMaterialRepository {
  final MaterialRemoteDataSource remoteDataSource;

  MaterialRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MaterialEntity>> getMaterialsByCourse(String courseId) async {
    try {
      final materialModels = await remoteDataSource.getMaterialsByCourse(
        courseId,
      );
      return materialModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<MaterialEntity>> getMaterialsByGroup(
    String courseId,
    String groupId,
  ) async {
    try {
      final materialModels = await remoteDataSource.getMaterialsByGroup(
        courseId,
        groupId,
      );
      return materialModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MaterialEntity?> getMaterialById(String materialId) async {
    try {
      final materialModel = await remoteDataSource.getMaterialById(materialId);
      return materialModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<MaterialEntity>> getMaterialsByType(
    String courseId,
    MaterialType type,
  ) async {
    try {
      final materialModels = await remoteDataSource.getMaterialsByType(
        courseId,
        type,
      );
      return materialModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MaterialEntity> createMaterial(MaterialEntity material) async {
    try {
      final materialModel = MaterialModel.fromEntity(material);
      final createdModel = await remoteDataSource.createMaterial(materialModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MaterialEntity> updateMaterial(MaterialEntity material) async {
    try {
      final materialModel = MaterialModel.fromEntity(material);
      final updatedModel = await remoteDataSource.updateMaterial(materialModel);
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteMaterial(String materialId) async {
    try {
      await remoteDataSource.deleteMaterial(materialId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> uploadFile(String filePath, String fileName) async {
    try {
      return await remoteDataSource.uploadFile(filePath, fileName);
    } catch (e) {
      rethrow;
    }
  }
}
