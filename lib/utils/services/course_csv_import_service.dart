import 'package:cloud_firestore/cloud_firestore.dart';
import 'csv_import_service.dart';

/// Data class for course CSV import
class CourseImportData {
  final String code;
  final String name;
  final String semesterId;
  final String instructorId;
  final String? description;
  final int sessions;
  final String? coverImageUrl;

  CourseImportData({
    required this.code,
    required this.name,
    required this.semesterId,
    required this.instructorId,
    this.description,
    this.sessions = 15,
    this.coverImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'semesterId': semesterId,
      'instructorId': instructorId,
      'description': description,
      'sessions': sessions,
      'coverImageUrl': coverImageUrl,
    };
  }
}

/// Service for importing courses from CSV
class CourseCsvImportService {
  final FirebaseFirestore _firestore;

  CourseCsvImportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Required columns for course CSV
  static const List<String> requiredColumns = [
    'code',
    'name',
    'semesterId',
    'instructorId',
  ];

  /// Optional columns for course CSV
  static const List<String> optionalColumns = [
    'description',
    'sessions',
    'coverImageUrl',
  ];

  /// Generate CSV template for courses
  static String generateTemplate() {
    return CsvImportService.generateTemplate(
      columns: [
        'code',
        'name',
        'semesterId',
        'instructorId',
        'description',
        'sessions',
        'coverImageUrl',
      ],
      sampleData: [
        [
          'CS101',
          'Introduction to Programming',
          'semester123',
          'instructor456',
          'Learn the basics of programming',
          '15',
          '',
        ],
        [
          'CS201',
          'Data Structures and Algorithms',
          'semester123',
          'instructor456',
          'Advanced data structures',
          '15',
          '',
        ],
      ],
    );
  }

  /// Parse and validate course CSV for preview
  Future<CsvImportResult<CourseImportData>> parseAndValidate(
    String csvContent, {
    String? defaultSemesterId,
    String? defaultInstructorId,
  }) async {
    return CsvImportService.parseAndValidate<CourseImportData>(
      csvContent: csvContent,
      requiredColumns: requiredColumns,
      validateRow: (row) => _validateCourseRow(
        row,
        defaultSemesterId: defaultSemesterId,
        defaultInstructorId: defaultInstructorId,
      ),
      checkDuplicate: _checkDuplicateCourse,
    );
  }

  /// Validate a single course row
  Future<CourseImportData?> _validateCourseRow(
    Map<String, dynamic> row, {
    String? defaultSemesterId,
    String? defaultInstructorId,
  }) async {
    final List<String> errors = [];

    // Validate course code (required)
    final code = row['code']?.toString().trim() ?? '';
    final codeError = CsvImportService.validateRequired(code, 'Course Code');
    if (codeError != null) {
      errors.add(codeError);
    } else {
      final lengthError = CsvImportService.validateLength(
        code,
        'Course Code',
        min: 3,
        max: 20,
      );
      if (lengthError != null) {
        errors.add(lengthError);
      }
    }

    // Validate course name (required)
    final name = row['name']?.toString().trim() ?? '';
    final nameError = CsvImportService.validateRequired(name, 'Course Name');
    if (nameError != null) {
      errors.add(nameError);
    } else {
      final lengthError = CsvImportService.validateLength(
        name,
        'Course Name',
        min: 3,
        max: 200,
      );
      if (lengthError != null) {
        errors.add(lengthError);
      }
    }

    // Validate semester ID (required, can use default)
    String semesterId = row['semesterId']?.toString().trim() ?? '';
    if (semesterId.isEmpty && defaultSemesterId != null) {
      semesterId = defaultSemesterId;
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

    // Validate instructor ID (required, can use default)
    String instructorId = row['instructorId']?.toString().trim() ?? '';
    if (instructorId.isEmpty && defaultInstructorId != null) {
      instructorId = defaultInstructorId;
    }

    if (instructorId.isEmpty) {
      errors.add('Instructor ID is required');
    } else {
      // Verify instructor exists
      final instructorExists = await _verifyInstructorExists(instructorId);
      if (!instructorExists) {
        errors.add('Instructor ID "$instructorId" does not exist');
      }
    }

    // Validate description (optional)
    final description = row['description']?.toString().trim();

    // Validate sessions (optional, default to 15)
    int sessions = 15;
    final sessionsStr = row['sessions']?.toString().trim() ?? '';
    if (sessionsStr.isNotEmpty) {
      final numericError = CsvImportService.validateNumeric(
        sessionsStr,
        'Sessions',
      );
      if (numericError != null) {
        errors.add(numericError);
      } else {
        sessions = int.tryParse(sessionsStr) ?? 15;
        if (sessions < 1 || sessions > 20) {
          errors.add('Sessions must be between 1 and 20');
        }
      }
    }

    // Validate cover image URL (optional)
    final coverImageUrl = row['coverImageUrl']?.toString().trim();

    if (errors.isNotEmpty) {
      throw Exception(errors.join('; '));
    }

    return CourseImportData(
      code: code,
      name: name,
      semesterId: semesterId,
      instructorId: instructorId,
      description: description,
      sessions: sessions,
      coverImageUrl: coverImageUrl,
    );
  }

  /// Check if course already exists (by code within the same semester)
  Future<bool> _checkDuplicateCourse(Map<String, dynamic> row) async {
    final code = row['code']?.toString().trim() ?? '';
    final semesterId = row['semesterId']?.toString().trim() ?? '';

    if (code.isEmpty || semesterId.isEmpty) {
      return false; // Will be caught by validation
    }

    // Check by code + semester combination
    final query = await _firestore
        .collection('courses')
        .where('code', isEqualTo: code)
        .where('semesterId', isEqualTo: semesterId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
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

  /// Verify instructor exists
  Future<bool> _verifyInstructorExists(String instructorId) async {
    try {
      final doc = await _firestore.collection('users').doc(instructorId).get();
      if (!doc.exists) return false;

      final role = doc.data()?['role'] as String?;
      return role == 'instructor';
    } catch (e) {
      return false;
    }
  }

  /// Process confirmed import
  Future<CsvImportFinalResult> processImport(
    List<CsvImportRow<CourseImportData>> rows,
  ) async {
    return CsvImportService.processImport<CourseImportData>(
      rows: rows,
      importRow: _importCourse,
    );
  }

  /// Import a single course
  Future<void> _importCourse(CourseImportData data) async {
    final docRef = _firestore.collection('courses').doc();

    await docRef.set({
      'id': docRef.id,
      'code': data.code,
      'name': data.name,
      'semesterId': data.semesterId,
      'instructorId': data.instructorId,
      'description': data.description,
      'sessions': data.sessions,
      'coverImageUrl': data.coverImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
