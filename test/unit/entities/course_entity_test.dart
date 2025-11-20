import 'package:flutter_test/flutter_test.dart';
import 'package:e_learning_management_app/domain/entities/course_entity.dart';

void main() {
  group('CourseEntity', () {
    test('should create course with valid data', () {
      // Act
      final course = CourseEntity(
        id: 'course1',
        name: 'Introduction to Flutter',
        code: 'CS101',
        instructorId: 'instructor1',
        semesterId: 'semester1',
        sessions: 20,
        coverImageUrl: 'https://example.com/image.jpg',
      );

      // Assert
      expect(course.id, 'course1');
      expect(course.name, 'Introduction to Flutter');
      expect(course.code, 'CS101');
      expect(course.instructorId, 'instructor1');
      expect(course.semesterId, 'semester1');
      expect(course.sessions, 20);
      expect(course.coverImageUrl, 'https://example.com/image.jpg');
    });

    test('should handle optional fields', () {
      // Act
      final course = CourseEntity(
        id: 'course1',
        name: 'Test Course',
        code: 'TEST101',
        instructorId: 'instructor1',
        semesterId: 'semester1',
        sessions: 10,
      );

      // Assert
      expect(course.coverImageUrl, null);
    });

    test('sessions should be positive number', () {
      // Act
      final course = CourseEntity(
        id: 'course1',
        name: 'Test Course',
        code: 'TEST101',
        instructorId: 'instructor1',
        semesterId: 'semester1',
        sessions: 15,
      );

      // Assert
      expect(course.sessions, greaterThan(0));
    });

    test('should have required fields', () {
      // Act
      final course = CourseEntity(
        id: 'course1',
        name: 'Test',
        code: 'TST101',
        instructorId: 'inst1',
        semesterId: 'sem1',
        sessions: 10,
      );

      // Assert
      expect(course.id, isNotEmpty);
      expect(course.name, isNotEmpty);
      expect(course.code, isNotEmpty);
      expect(course.instructorId, isNotEmpty);
      expect(course.semesterId, isNotEmpty);
    });
  });
}
