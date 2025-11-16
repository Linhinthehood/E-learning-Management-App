import 'package:hive/hive.dart';
import '../models/course_model.dart';

/// Local data source for Course caching using Hive
abstract class CourseLocalDataSource {
  Future<List<CourseModel>> getCachedCourses(String semesterId);
  Future<void> cacheCourses(String semesterId, List<CourseModel> courses);
  Future<void> clearCache();
  Future<void> clearCacheForSemester(String semesterId);
}

/// Implementation of CourseLocalDataSource using Hive
class CourseLocalDataSourceImpl implements CourseLocalDataSource {
  static const String _boxName = 'courseBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  String _getKey(String semesterId) => 'courses_$semesterId';

  @override
  Future<List<CourseModel>> getCachedCourses(String semesterId) async {
    try {
      final box = await _getBox();
      final cachedData = box.get(_getKey(semesterId));

      if (cachedData != null && cachedData is List) {
        return cachedData.map((item) {
          final map = Map<String, dynamic>.from(item);
          final id = map['id'] as String;
          return CourseModel.fromJson(map, id);
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheCourses(
    String semesterId,
    List<CourseModel> courses,
  ) async {
    try {
      final box = await _getBox();
      final coursesJson = courses.map((c) {
        final json = c.toJson();
        json['id'] = c.id; // Include ID in cached JSON
        return json;
      }).toList();
      await box.put(_getKey(semesterId), coursesJson);
      // Also store last sync timestamp
      await box.put(
        '${_getKey(semesterId)}_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  @override
  Future<void> clearCacheForSemester(String semesterId) async {
    try {
      final box = await _getBox();
      await box.delete(_getKey(semesterId));
      await box.delete('${_getKey(semesterId)}_timestamp');
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      // Silently fail
    }
  }

  /// Get last sync timestamp for semester courses
  Future<DateTime?> getLastSyncTime(String semesterId) async {
    try {
      final box = await _getBox();
      final timestamp = box.get('${_getKey(semesterId)}_timestamp');
      if (timestamp != null && timestamp is String) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }
}
