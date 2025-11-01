/// Course entity representing a course in the system
class CourseEntity {
  final String id;
  final String name;
  final String code;
  final String semesterId;
  final String instructorId;
  final String? coverImageUrl;
  final int sessions;

  const CourseEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.semesterId,
    required this.instructorId,
    this.coverImageUrl,
    required this.sessions,
  });
}
