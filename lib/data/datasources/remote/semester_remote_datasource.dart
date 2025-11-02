import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/semester_model.dart';

/// Remote data source for Semester operations using Firebase Firestore
abstract class SemesterRemoteDataSource {
  Future<List<SemesterModel>> getAllSemesters();
  Future<SemesterModel?> getSemesterById(String id);
  Future<void> createSemester(SemesterModel semester);
  Future<void> updateSemester(SemesterModel semester);
  Future<void> deleteSemester(String id);
  Future<bool> semesterCodeExists(String code, {String? excludeId});
}

/// Implementation of SemesterRemoteDataSource using Firestore
class SemesterRemoteDataSourceImpl implements SemesterRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'semesters';

  @override
  Future<List<SemesterModel>> getAllSemesters() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('startDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SemesterModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get semesters: ${e.toString()}');
    }
  }

  @override
  Future<SemesterModel?> getSemesterById(String id) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(id)
          .get();

      if (docSnapshot.exists) {
        return SemesterModel.fromJson({
          'id': docSnapshot.id,
          ...docSnapshot.data()!,
        });
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get semester: ${e.toString()}');
    }
  }

  @override
  Future<void> createSemester(SemesterModel semester) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(semester.id)
          .set(semester.toJson()..remove('id'));
    } catch (e) {
      throw Exception('Failed to create semester: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSemester(SemesterModel semester) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(semester.id)
          .update(semester.toJson()..remove('id'));
    } catch (e) {
      throw Exception('Failed to update semester: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteSemester(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete semester: ${e.toString()}');
    }
  }

  @override
  Future<bool> semesterCodeExists(String code, {String? excludeId}) async {
    try {
      var query = _firestore
          .collection(_collection)
          .where('code', isEqualTo: code)
          .limit(1);

      final querySnapshot = await query.get();

      if (excludeId != null) {
        // If we're excluding an ID (for updates), check if the found doc is not the one we're excluding
        return querySnapshot.docs.isNotEmpty &&
            querySnapshot.docs.first.id != excludeId;
      }

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check semester code: ${e.toString()}');
    }
  }
}
