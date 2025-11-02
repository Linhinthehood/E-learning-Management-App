/// Enrollment entity representing student enrollment in a course group
class EnrollmentEntity {
  final String id;
  final String studentId;
  final String courseId;
  final String groupId;
  final String semesterId;

  const EnrollmentEntity({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.groupId,
    required this.semesterId,
  });
}

