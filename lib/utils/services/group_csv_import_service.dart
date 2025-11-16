import 'package:cloud_firestore/cloud_firestore.dart';
import 'csv_import_service.dart';

/// Data class for group CSV import
class GroupImportData {
  final String name;
  final String courseId;
  final String semesterId;
  final List<String>?
  studentIds; // Optional: comma-separated student emails or IDs

  GroupImportData({
    required this.name,
    required this.courseId,
    required this.semesterId,
    this.studentIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'courseId': courseId,
      'semesterId': semesterId,
      'studentIds': studentIds,
    };
  }
}

/// Service for importing groups from CSV
class GroupCsvImportService {
  final FirebaseFirestore _firestore;

  GroupCsvImportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Required columns for group CSV
  static const List<String> requiredColumns = ['name', 'courseId'];

  /// Optional columns for group CSV
  static const List<String> optionalColumns = [
    'semesterId',
    'studentEmails', // Comma-separated list of student emails
  ];

  /// Generate CSV template for groups
  static String generateTemplate() {
    return CsvImportService.generateTemplate(
      columns: ['name', 'courseId', 'semesterId', 'studentEmails'],
      sampleData: [
        [
          'Group 1',
          'course123',
          'semester456',
          'student1@example.com,student2@example.com',
        ],
        [
          'Group 2',
          'course123',
          'semester456',
          'student3@example.com,student4@example.com',
        ],
      ],
    );
  }

  /// Parse and validate group CSV for preview
  Future<CsvImportResult<GroupImportData>> parseAndValidate(
    String csvContent, {
    String? defaultCourseId,
    String? defaultSemesterId,
  }) async {
    return CsvImportService.parseAndValidate<GroupImportData>(
      csvContent: csvContent,
      requiredColumns: requiredColumns,
      validateRow: (row) => _validateGroupRow(
        row,
        defaultCourseId: defaultCourseId,
        defaultSemesterId: defaultSemesterId,
      ),
      checkDuplicate: _checkDuplicateGroup,
    );
  }

  /// Validate a single group row
  Future<GroupImportData?> _validateGroupRow(
    Map<String, dynamic> row, {
    String? defaultCourseId,
    String? defaultSemesterId,
  }) async {
    final List<String> errors = [];

    // Validate group name (required)
    final name = row['name']?.toString().trim() ?? '';
    final nameError = CsvImportService.validateRequired(name, 'Group Name');
    if (nameError != null) {
      errors.add(nameError);
    } else {
      final lengthError = CsvImportService.validateLength(
        name,
        'Group Name',
        min: 2,
        max: 100,
      );
      if (lengthError != null) {
        errors.add(lengthError);
      }
    }

    // Validate course ID (required, can use default)
    String courseId = row['courseId']?.toString().trim() ?? '';
    if (courseId.isEmpty && defaultCourseId != null) {
      courseId = defaultCourseId;
    }

    if (courseId.isEmpty) {
      errors.add('Course ID is required');
    } else {
      // Verify course exists and get its semester
      final courseData = await _verifyCourseExists(courseId);
      if (courseData == null) {
        errors.add('Course ID "$courseId" does not exist');
      }
    }

    // Validate semester ID (optional, can use default or from course)
    String semesterId = row['semesterId']?.toString().trim() ?? '';
    if (semesterId.isEmpty && defaultSemesterId != null) {
      semesterId = defaultSemesterId;
    } else if (semesterId.isEmpty && courseId.isNotEmpty) {
      // Get semester from course
      final courseData = await _verifyCourseExists(courseId);
      if (courseData != null) {
        semesterId = courseData['semesterId'] as String? ?? '';
      }
    }

    if (semesterId.isEmpty) {
      errors.add('Semester ID is required');
    } else {
      // Verify semester exists
      final semesterExists = await _verifySemesterExists(semesterId);
      if (!semesterExists) {
        errors.add('Semester ID "$semesterId" does not exist');
      }
    }

    // Validate student emails (optional)
    List<String>? studentIds;
    final studentEmailsStr = row['studentEmails']?.toString().trim();
    if (studentEmailsStr != null && studentEmailsStr.isNotEmpty) {
      final emails = studentEmailsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Validate each email and resolve to student IDs
      studentIds = [];
      for (final email in emails) {
        if (!CsvImportService.isValidEmail(email)) {
          errors.add('Invalid student email: $email');
          continue;
        }

        final studentId = await _getStudentIdByEmail(email);
        if (studentId == null) {
          errors.add('Student with email "$email" not found');
        } else {
          studentIds.add(studentId);
        }
      }

      if (studentIds.isEmpty) {
        studentIds = null;
      }
    }

    if (errors.isNotEmpty) {
      throw Exception(errors.join('; '));
    }

    return GroupImportData(
      name: name,
      courseId: courseId,
      semesterId: semesterId,
      studentIds: studentIds,
    );
  }

  /// Check if group already exists (by name within the same course)
  Future<bool> _checkDuplicateGroup(Map<String, dynamic> row) async {
    final name = row['name']?.toString().trim() ?? '';
    final courseId = row['courseId']?.toString().trim() ?? '';

    if (name.isEmpty || courseId.isEmpty) {
      return false; // Will be caught by validation
    }

    // Check by name + course combination
    final query = await _firestore
        .collection('groups')
        .where('name', isEqualTo: name)
        .where('courseId', isEqualTo: courseId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Verify course exists and return its data
  Future<Map<String, dynamic>?> _verifyCourseExists(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  /// Verify semester exists
  Future<bool> _verifySemesterExists(String semesterId) async {
    try {
      final doc = await _firestore
          .collection('semesters')
          .doc(semesterId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get student ID by email
  Future<String?> _getStudentIdByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'student')
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return query.docs.first.id;
    } catch (e) {
      return null;
    }
  }

  /// Process confirmed import
  Future<CsvImportFinalResult> processImport(
    List<CsvImportRow<GroupImportData>> rows,
  ) async {
    return CsvImportService.processImport<GroupImportData>(
      rows: rows,
      importRow: _importGroup,
    );
  }

  /// Import a single group
  Future<void> _importGroup(GroupImportData data) async {
    final docRef = _firestore.collection('groups').doc();

    // Create group
    await docRef.set({
      'id': docRef.id,
      'name': data.name,
      'courseId': data.courseId,
      'semesterId': data.semesterId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Create enrollments for students if provided
    if (data.studentIds != null && data.studentIds!.isNotEmpty) {
      final batch = _firestore.batch();

      for (final studentId in data.studentIds!) {
        // Check if student is already enrolled in this course
        final existingEnrollment = await _firestore
            .collection('enrollments')
            .where('studentId', isEqualTo: studentId)
            .where('courseId', isEqualTo: data.courseId)
            .limit(1)
            .get();

        if (existingEnrollment.docs.isNotEmpty) {
          // Update existing enrollment with new group
          final enrollmentDoc = existingEnrollment.docs.first;
          batch.update(enrollmentDoc.reference, {
            'groupId': docRef.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new enrollment
          final enrollmentRef = _firestore.collection('enrollments').doc();
          batch.set(enrollmentRef, {
            'id': enrollmentRef.id,
            'studentId': studentId,
            'courseId': data.courseId,
            'groupId': docRef.id,
            'semesterId': data.semesterId,
            'enrolledAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    }
  }
}
