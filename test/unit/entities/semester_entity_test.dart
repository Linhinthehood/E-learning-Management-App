import 'package:flutter_test/flutter_test.dart';
import 'package:e_learning_management_app/domain/entities/semester_entity.dart';

void main() {
  group('SemesterEntity', () {
    test('should create semester with valid data', () {
      // Arrange
      final startDate = DateTime(2025, 1, 1);
      final endDate = DateTime(2025, 6, 30);
      final createdAt = DateTime.now();

      // Act
      final semester = SemesterEntity(
        id: 'sem1',
        name: 'Spring 2025',
        code: 'SP2025',
        startDate: startDate,
        endDate: endDate,
        createdAt: createdAt,
      );

      // Assert
      expect(semester.id, 'sem1');
      expect(semester.name, 'Spring 2025');
      expect(semester.code, 'SP2025');
      expect(semester.startDate, startDate);
      expect(semester.endDate, endDate);
    });

    test('isPast should return true for past semesters', () {
      // Arrange
      final pastSemester = SemesterEntity(
        id: 'sem1',
        name: 'Fall 2020',
        code: 'FA2020',
        startDate: DateTime(2020, 9, 1),
        endDate: DateTime(2020, 12, 31),
        createdAt: DateTime(2020, 8, 1),
      );

      // Act & Assert
      expect(pastSemester.isPast, true);
    });

    test('isFuture should return true for future semesters', () {
      // Arrange
      final futureSemester = SemesterEntity(
        id: 'sem1',
        name: 'Fall 2030',
        code: 'FA2030',
        startDate: DateTime(2030, 9, 1),
        endDate: DateTime(2030, 12, 31),
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(futureSemester.isFuture, true);
    });

    test('status should return correct status string', () {
      // Arrange
      final activeSemester = SemesterEntity(
        id: 'sem1',
        name: 'Current',
        code: 'CUR',
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now().add(Duration(days: 30)),
        createdAt: DateTime.now().subtract(Duration(days: 60)),
      );

      final pastSemester = SemesterEntity(
        id: 'sem2',
        name: 'Past',
        code: 'PST',
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 6, 30),
        createdAt: DateTime(2019, 12, 1),
      );

      // Act & Assert
      expect(activeSemester.status, 'Active');
      expect(pastSemester.status, 'Past');
    });

    test('durationInDays should calculate correct duration', () {
      // Arrange
      final semester = SemesterEntity(
        id: 'sem1',
        name: 'Test',
        code: 'TST',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 6, 30),
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(semester.durationInDays, greaterThan(0));
    });
  });
}
