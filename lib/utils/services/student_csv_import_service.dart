import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import 'csv_import_service.dart';

/// Data class for student CSV import
class StudentImportData {
  final String email;
  final String displayName;
  final String? phone;
  final String? studentId;
  final String password; // Generated or provided

  StudentImportData({
    required this.email,
    required this.displayName,
    this.phone,
    this.studentId,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'studentId': studentId,
      'password': password,
      'role': UserRole.student.name,
    };
  }
}

/// Service for importing students from CSV
class StudentCsvImportService {
  final FirebaseFirestore _firestore;

  StudentCsvImportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Required columns for student CSV
  static const List<String> requiredColumns = ['email', 'displayName'];

  /// Optional columns for student CSV
  static const List<String> optionalColumns = [
    'phone',
    'studentId',
    'password', // If not provided, will be auto-generated
  ];

  /// Generate CSV template for students
  static String generateTemplate() {
    return CsvImportService.generateTemplate(
      columns: ['email', 'displayName', 'phone', 'studentId', 'password'],
      sampleData: [
        [
          'john.doe@example.com',
          'John Doe',
          '0123456789',
          'IT2023001',
          'Password123!',
        ],
        [
          'jane.smith@example.com',
          'Jane Smith',
          '0987654321',
          'IT2023002',
          'SecurePass456!',
        ],
      ],
    );
  }

  /// Parse and validate student CSV for preview
  Future<CsvImportResult<StudentImportData>> parseAndValidate(
    String csvContent,
  ) async {
    return CsvImportService.parseAndValidate<StudentImportData>(
      csvContent: csvContent,
      requiredColumns: requiredColumns,
      validateRow: _validateStudentRow,
      checkDuplicate: _checkDuplicateStudent,
    );
  }

  /// Validate a single student row
  Future<StudentImportData?> _validateStudentRow(
    Map<String, dynamic> row,
  ) async {
    final List<String> errors = [];

    // Validate email (required)
    final email = row['email']?.toString().trim() ?? '';
    final emailError = CsvImportService.validateRequired(email, 'Email');
    if (emailError != null) {
      errors.add(emailError);
    } else if (!CsvImportService.isValidEmail(email)) {
      errors.add('Invalid email format');
    }

    // Validate display name (required)
    final displayName = row['displayName']?.toString().trim() ?? '';
    final nameError = CsvImportService.validateRequired(
      displayName,
      'Display Name',
    );
    if (nameError != null) {
      errors.add(nameError);
    } else {
      final lengthError = CsvImportService.validateLength(
        displayName,
        'Display Name',
        min: 2,
        max: 100,
      );
      if (lengthError != null) {
        errors.add(lengthError);
      }
    }

    // Validate phone (optional)
    final phone = row['phone']?.toString().trim();
    if (phone != null && phone.isNotEmpty) {
      if (phone.length < 10 || phone.length > 15) {
        errors.add('Phone number must be between 10-15 digits');
      }
    }

    // Validate student ID (optional)
    final studentId = row['studentId']?.toString().trim();
    if (studentId != null && studentId.isNotEmpty) {
      final lengthError = CsvImportService.validateLength(
        studentId,
        'Student ID',
        min: 5,
        max: 20,
      );
      if (lengthError != null) {
        errors.add(lengthError);
      }
    }

    // Validate or generate password
    String password = row['password']?.toString().trim() ?? '';
    if (password.isEmpty) {
      // Auto-generate password if not provided
      password = _generatePassword();
    } else {
      // Validate provided password
      if (password.length < 6) {
        errors.add('Password must be at least 6 characters');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception(errors.join('; '));
    }

    return StudentImportData(
      email: email,
      displayName: displayName,
      phone: phone,
      studentId: studentId,
      password: password,
    );
  }

  /// Check if student already exists (by email or studentId)
  Future<bool> _checkDuplicateStudent(Map<String, dynamic> row) async {
    final email = row['email']?.toString().trim() ?? '';
    final studentId = row['studentId']?.toString().trim();

    if (email.isEmpty) {
      return false; // Will be caught by validation
    }

    // Check by email
    final emailQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (emailQuery.docs.isNotEmpty) {
      return true;
    }

    // Check by student ID if provided
    if (studentId != null && studentId.isNotEmpty) {
      final studentIdQuery = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .where('role', isEqualTo: UserRole.student.name)
          .limit(1)
          .get();

      if (studentIdQuery.docs.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Process confirmed import
  Future<CsvImportFinalResult> processImport(
    List<CsvImportRow<StudentImportData>> rows,
  ) async {
    return CsvImportService.processImport<StudentImportData>(
      rows: rows,
      importRow: _importStudent,
    );
  }

  /// Import a single student
  Future<void> _importStudent(StudentImportData data) async {
    // Note: In a real implementation, you would use Firebase Auth
    // to create the user account with email and password
    // For now, we'll just create the user document in Firestore

    final docRef = _firestore.collection('users').doc();

    await docRef.set({
      'uid': docRef.id,
      'email': data.email,
      'displayName': data.displayName,
      'phone': data.phone,
      'studentId': data.studentId,
      'role': UserRole.student.name,
      'avatarUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // Note: Password should be hashed and handled via Firebase Auth
      // Storing it here is just for demonstration
      '_tempPassword':
          data.password, // Temporary, should be removed in production
    });
  }

  /// Generate a random password
  String _generatePassword() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'Student${random.substring(random.length - 6)}!';
  }
}
