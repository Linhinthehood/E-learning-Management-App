import 'package:flutter_test/flutter_test.dart';

// Email validation function
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

// Student ID validation function
bool isValidStudentId(String? id) {
  if (id == null || id.isEmpty) return false;
  return id.length >= 5 && id.length <= 20;
}

// Course code validation function
bool isValidCourseCode(String? code) {
  if (code == null || code.isEmpty) return false;
  final codeRegex = RegExp(r'^[A-Z]{2,4}\d{3,4}$');
  return codeRegex.hasMatch(code);
}

void main() {
  group('Email Validation', () {
    test('should accept valid email addresses', () {
      expect(isValidEmail('test@example.com'), true);
      expect(isValidEmail('user.name@domain.co.uk'), true);
      expect(isValidEmail('student123@university.edu'), true);
    });

    test('should reject invalid email addresses', () {
      expect(isValidEmail('invalid'), false);
      expect(isValidEmail('test@'), false);
      expect(isValidEmail('@example.com'), false);
      expect(isValidEmail('test@.com'), false);
      expect(isValidEmail(''), false);
    });
  });

  group('Student ID Validation', () {
    test('should accept valid student IDs', () {
      expect(isValidStudentId('12345'), true);
      expect(isValidStudentId('STU001'), true);
      expect(isValidStudentId('2025001234'), true);
    });

    test('should reject invalid student IDs', () {
      expect(isValidStudentId('1234'), false); // Too short
      expect(isValidStudentId(''), false); // Empty
      expect(isValidStudentId(null), false); // Null
      expect(isValidStudentId('123456789012345678901'), false); // Too long
    });
  });

  group('Course Code Validation', () {
    test('should accept valid course codes', () {
      expect(isValidCourseCode('CS101'), true);
      expect(isValidCourseCode('MATH2001'), true);
      expect(isValidCourseCode('ENG101'), true);
    });

    test('should reject invalid course codes', () {
      expect(isValidCourseCode('cs101'), false); // Lowercase
      expect(isValidCourseCode('C101'), false); // Too short prefix
      expect(isValidCourseCode('CSCI10'), false); // Too short number
      expect(isValidCourseCode('CS10000'), false); // Too long number
      expect(isValidCourseCode(''), false); // Empty
      expect(isValidCourseCode(null), false); // Null
    });
  });

  group('Name Validation', () {
    test('should validate display names', () {
      bool isValidName(String? name) {
        if (name == null || name.trim().isEmpty) return false;
        return name.trim().length >= 2 && name.trim().length <= 50;
      }

      expect(isValidName('John Doe'), true);
      expect(isValidName('A'), false); // Too short
      expect(isValidName(''), false); // Empty
      expect(isValidName('A' * 51), false); // Too long
    });
  });

  group('Date Validation', () {
    test('should validate date ranges', () {
      bool isValidDateRange(DateTime start, DateTime end) {
        return start.isBefore(end);
      }

      final today = DateTime.now();
      final tomorrow = today.add(Duration(days: 1));
      final yesterday = today.subtract(Duration(days: 1));

      expect(isValidDateRange(today, tomorrow), true);
      expect(isValidDateRange(tomorrow, today), false);
      expect(isValidDateRange(yesterday, today), true);
    });
  });
}
