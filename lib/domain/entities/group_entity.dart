/// Group entity representing a group (class) within a course
class GroupEntity {
  final String id;
  final String name;
  final String courseId;
  final String semesterId;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.courseId,
    required this.semesterId,
  });
}

