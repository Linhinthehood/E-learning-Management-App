import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_model.dart';
import '../../../domain/entities/material_entity.dart';

/// Remote data source for materials
/// Handles Firestore calls for course materials
abstract class MaterialRemoteDataSource {
  Future<List<MaterialModel>> getMaterialsByCourse(String courseId);
  Future<List<MaterialModel>> getMaterialsByGroup(
    String courseId,
    String groupId,
  );
  Future<MaterialModel?> getMaterialById(String materialId);
  Future<List<MaterialModel>> getMaterialsByType(
    String courseId,
    MaterialType type,
  );
  Future<MaterialModel> createMaterial(MaterialModel material);
  Future<MaterialModel> updateMaterial(MaterialModel material);
  Future<void> deleteMaterial(String materialId);
  Future<String> uploadFile(String filePath, String fileName);
}

/// Implementation of MaterialRemoteDataSource using Firestore
class MaterialRemoteDataSourceImpl implements MaterialRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<MaterialModel>> getMaterialsByCourse(String courseId) async {
    try {
      // Get all materials for the course (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('materials')
          .where('courseId', isEqualTo: courseId)
          .get();

      final materials = querySnapshot.docs
          .map((doc) => MaterialModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory by createdAt (descending)
      materials.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return materials;
    } catch (e) {
      throw Exception('Failed to get materials: ${e.toString()}');
    }
  }

  @override
  Future<List<MaterialModel>> getMaterialsByGroup(
    String courseId,
    String groupId,
  ) async {
    try {
      // Get materials for the course and group (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('materials')
          .where('courseId', isEqualTo: courseId)
          .where('scopedGroupIds', arrayContains: groupId)
          .get();

      final materials = querySnapshot.docs
          .map((doc) => MaterialModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory by createdAt (descending)
      materials.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return materials;
    } catch (e) {
      throw Exception('Failed to get group materials: ${e.toString()}');
    }
  }

  @override
  Future<MaterialModel?> getMaterialById(String materialId) async {
    try {
      final docSnapshot = await _firestore
          .collection('materials')
          .doc(materialId)
          .get();

      if (!docSnapshot.exists) return null;
      return MaterialModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get material: ${e.toString()}');
    }
  }

  @override
  Future<List<MaterialModel>> getMaterialsByType(
    String courseId,
    MaterialType type,
  ) async {
    try {
      // Get materials and filter in memory (without complex orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('materials')
          .where('courseId', isEqualTo: courseId)
          .where('type', isEqualTo: type.name)
          .get();

      final materials = querySnapshot.docs
          .map((doc) => MaterialModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory by createdAt (descending)
      materials.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return materials;
    } catch (e) {
      throw Exception('Failed to get materials by type: ${e.toString()}');
    }
  }

  @override
  Future<MaterialModel> createMaterial(MaterialModel material) async {
    try {
      final docRef = await _firestore
          .collection('materials')
          .add(material.toJson());

      final docSnapshot = await docRef.get();
      return MaterialModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create material: ${e.toString()}');
    }
  }

  @override
  Future<MaterialModel> updateMaterial(MaterialModel material) async {
    try {
      final updatedMaterial = MaterialModel(
        id: material.id,
        title: material.title,
        description: material.description,
        files: material.files,
        courseId: material.courseId,
        scopedGroupIds: material.scopedGroupIds,
        type: material.type,
        createdAt: material.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('materials')
          .doc(material.id)
          .update(updatedMaterial.toJson());

      return updatedMaterial;
    } catch (e) {
      throw Exception('Failed to update material: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMaterial(String materialId) async {
    try {
      await _firestore.collection('materials').doc(materialId).delete();
    } catch (e) {
      throw Exception('Failed to delete material: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadFile(String filePath, String fileName) async {
    // TODO: Implement Firebase Storage upload
    // This is a placeholder - actual implementation would use Firebase Storage
    try {
      // Example using Firebase Storage:
      // final ref = FirebaseStorage.instance.ref().child('materials/$fileName');
      // final uploadTask = await ref.putFile(File(filePath));
      // final downloadUrl = await uploadTask.ref.getDownloadURL();
      // return downloadUrl;

      throw UnimplementedError(
        'File upload not yet implemented - requires Firebase Storage setup',
      );
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }
}
