/// Semester entity for managing academic semesters
class SemesterEntity {
  final String id;
  final String name;
  final String code;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  const SemesterEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  /// Check if this semester is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get semester duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays;
  }
}
