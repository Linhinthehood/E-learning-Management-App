import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

/// Remote data source for courses
/// Handles Firestore calls for courses and enrollments
abstract class CourseRemoteDataSource {
  /// Get all courses for a semester
  Future<List<CourseModel>> getCoursesBySemester(String semesterId);

  /// Get a single course by ID
  Future<CourseModel?> getCourseById(String courseId);

  /// Get courses that a student is enrolled in for a semester
  Future<List<CourseModel>> getStudentCourses(String studentId, String semesterId);

  /// Get instructor information for a course
  Future<Map<String, String>?> getInstructorInfo(String instructorId);

  /// Create a new course
  Future<CourseModel> createCourse(CourseModel course);

  /// Update an existing course
  Future<CourseModel> updateCourse(CourseModel course);

  /// Delete a course
  Future<void> deleteCourse(String courseId);
}

/// Implementation of CourseRemoteDataSource using Firestore
class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<CourseModel>> getCoursesBySemester(String semesterId) async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('semesterId', isEqualTo: semesterId)
          .get();

      return querySnapshot.docs
          .map((doc) => CourseModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get courses: ${e.toString()}');
    }
  }

  @override
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (doc.exists) {
        return CourseModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get course: ${e.toString()}');
    }
  }

  @override
  Future<List<CourseModel>> getStudentCourses(String studentId, String semesterId) async {
    try {
      // Get all enrollments for this student in this semester
      final enrollmentSnapshot = await _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('semesterId', isEqualTo: semesterId)
          .get();

      if (enrollmentSnapshot.docs.isEmpty) {
        return [];
      }

      // Extract unique course IDs from enrollments
      final courseIds = enrollmentSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toSet()
          .toList();

      if (courseIds.isEmpty) {
        return [];
      }

      // Get course details for each enrolled course
      final courses = <CourseModel>[];
      for (final courseId in courseIds) {
        final course = await getCourseById(courseId);
        if (course != null) {
          courses.add(course);
        }
      }

      return courses;
    } catch (e) {
      throw Exception('Failed to get student courses: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, String>?> getInstructorInfo(String instructorId) async {
    try {
      final doc = await _firestore.collection('users').doc(instructorId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'name': data['displayName'] as String? ?? 'Unknown',
          'email': data['email'] as String? ?? '',
          'avatarUrl': data['avatarUrl'] as String? ?? '',
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CourseModel> createCourse(CourseModel course) async {
    try {
      final docRef = await _firestore.collection('courses').add(course.toJson());
      final createdDoc = await docRef.get();
      return CourseModel.fromJson(createdDoc.data()!, createdDoc.id);
    } catch (e) {
      throw Exception('Failed to create course: ${e.toString()}');
    }
  }

  @override
  Future<CourseModel> updateCourse(CourseModel course) async {
    try {
      await _firestore
          .collection('courses')
          .doc(course.id)
          .update(course.toJson());
      return course;
    } catch (e) {
      throw Exception('Failed to update course: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
    } catch (e) {
      throw Exception('Failed to delete course: ${e.toString()}');
    }
  }
}

