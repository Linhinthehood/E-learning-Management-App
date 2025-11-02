import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enrollment_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

/// Remote data source for enrollments
/// Handles Firestore calls for enrollments, groups, and students
abstract class EnrollmentRemoteDataSource {
  /// Get all enrollments for a course
  Future<List<EnrollmentModel>> getEnrollmentsByCourse(String courseId);

  /// Get all enrollments for a student in a semester
  Future<List<EnrollmentModel>> getEnrollmentsByStudent(
    String studentId,
    String semesterId,
  );

  /// Get enrollment for a student in a specific course
  Future<EnrollmentModel?> getEnrollmentByStudentAndCourse(
    String studentId,
    String courseId,
  );

  /// Create a new enrollment
  Future<EnrollmentModel> createEnrollment(EnrollmentModel enrollment);

  /// Delete an enrollment
  Future<void> deleteEnrollment(String enrollmentId);

  /// Get all students (users with role=student)
  Future<List<UserModel>> getAllStudents();

  /// Check if student is already enrolled in the course
  Future<bool> isStudentEnrolledInCourse(String studentId, String courseId);

  /// Get all groups for a course
  Future<List<GroupModel>> getGroupsByCourse(String courseId);

  /// Create a new group
  Future<GroupModel> createGroup(GroupModel group);

  /// Get a group by ID
  Future<GroupModel?> getGroupById(String groupId);

  /// Delete a group
  Future<void> deleteGroup(String groupId);
}

/// Implementation of EnrollmentRemoteDataSource using Firestore
class EnrollmentRemoteDataSourceImpl implements EnrollmentRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<EnrollmentModel>> getEnrollmentsByCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: courseId)
          .get();

      return querySnapshot.docs
          .map((doc) => EnrollmentModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get enrollments: ${e.toString()}');
    }
  }

  @override
  Future<List<EnrollmentModel>> getEnrollmentsByStudent(
    String studentId,
    String semesterId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('semesterId', isEqualTo: semesterId)
          .get();

      return querySnapshot.docs
          .map((doc) => EnrollmentModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get student enrollments: ${e.toString()}');
    }
  }

  @override
  Future<EnrollmentModel?> getEnrollmentByStudentAndCourse(
    String studentId,
    String courseId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return EnrollmentModel.fromJson(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get enrollment: ${e.toString()}');
    }
  }

  @override
  Future<EnrollmentModel> createEnrollment(EnrollmentModel enrollment) async {
    try {
      // Check if student is already enrolled in this course
      final existingEnrollment = await getEnrollmentByStudentAndCourse(
        enrollment.studentId,
        enrollment.courseId,
      );

      if (existingEnrollment != null) {
        throw Exception('Student is already enrolled in this course');
      }

      // Create enrollment
      final docRef = await _firestore
          .collection('enrollments')
          .add(enrollment.toJson());
      final createdDoc = await docRef.get();
      return EnrollmentModel.fromJson(createdDoc.data()!, createdDoc.id);
    } catch (e) {
      throw Exception('Failed to create enrollment: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteEnrollment(String enrollmentId) async {
    try {
      await _firestore.collection('enrollments').doc(enrollmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete enrollment: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getAllStudents() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson({'uid': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get students: ${e.toString()}');
    }
  }

  @override
  Future<bool> isStudentEnrolledInCourse(
    String studentId,
    String courseId,
  ) async {
    try {
      final enrollment = await getEnrollmentByStudentAndCourse(
        studentId,
        courseId,
      );
      return enrollment != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<GroupModel>> getGroupsByCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('courseId', isEqualTo: courseId)
          .get();

      return querySnapshot.docs
          .map((doc) => GroupModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get groups: ${e.toString()}');
    }
  }

  @override
  Future<GroupModel> createGroup(GroupModel group) async {
    try {
      final docRef = await _firestore.collection('groups').add(group.toJson());
      final createdDoc = await docRef.get();
      return GroupModel.fromJson(createdDoc.data()!, createdDoc.id);
    } catch (e) {
      throw Exception('Failed to create group: ${e.toString()}');
    }
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get group: ${e.toString()}');
    }
  }

  @override
  /// Delete a group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).delete();
    } catch (e) {
      throw Exception('Failed to delete group: ${e.toString()}');
    }
  }
}
