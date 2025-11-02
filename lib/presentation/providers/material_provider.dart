import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/material_remote_datasource.dart';
import '../../data/repositories/material_repository_impl.dart';
import '../../domain/entities/material_entity.dart';
import '../../domain/repositories/i_material_repository.dart';

/// Provider for material remote data source
final materialRemoteDataSourceProvider = Provider<MaterialRemoteDataSource>((ref) {
  return MaterialRemoteDataSourceImpl();
});

/// Provider for material repository
final materialRepositoryProvider = Provider<IMaterialRepository>((ref) {
  return MaterialRepositoryImpl(
    remoteDataSource: ref.read(materialRemoteDataSourceProvider),
  );
});

/// Material state notifier - manages course materials
class MaterialNotifier extends StateNotifier<AsyncValue<List<MaterialEntity>>> {
  final IMaterialRepository _repository;
  String? _currentCourseId;

  MaterialNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load materials for a course
  Future<void> loadMaterials(String courseId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final materials = await _repository.getMaterialsByCourse(courseId);
      state = AsyncValue.data(materials);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load materials for a specific group
  Future<void> loadGroupMaterials(String courseId, String groupId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final materials = await _repository.getMaterialsByGroup(courseId, groupId);
      state = AsyncValue.data(materials);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load materials by type
  Future<void> loadMaterialsByType(String courseId, MaterialType type) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final materials = await _repository.getMaterialsByType(courseId, type);
      state = AsyncValue.data(materials);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new material
  Future<void> createMaterial(MaterialEntity material) async {
    try {
      await _repository.createMaterial(material);
      if (_currentCourseId != null) {
        await loadMaterials(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing material
  Future<void> updateMaterial(MaterialEntity material) async {
    try {
      await _repository.updateMaterial(material);
      if (_currentCourseId != null) {
        await loadMaterials(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a material
  Future<void> deleteMaterial(String materialId) async {
    try {
      await _repository.deleteMaterial(materialId);
      if (_currentCourseId != null) {
        await loadMaterials(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload a file
  Future<String> uploadFile(String filePath, String fileName) async {
    try {
      return await _repository.uploadFile(filePath, fileName);
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current materials
  Future<void> refresh() async {
    if (_currentCourseId != null) {
      await loadMaterials(_currentCourseId!);
    }
  }
}

/// Provider for material state notifier
final materialProvider = StateNotifierProvider<MaterialNotifier, AsyncValue<List<MaterialEntity>>>((ref) {
  return MaterialNotifier(ref.read(materialRepositoryProvider));
});

/// Provider for fetching a single material by ID
final materialByIdProvider = FutureProvider.family<MaterialEntity?, String>((ref, materialId) async {
  final repository = ref.read(materialRepositoryProvider);
  return await repository.getMaterialById(materialId);
});
