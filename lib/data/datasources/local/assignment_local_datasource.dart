import 'package:hive/hive.dart';
import '../models/assignment_model.dart';

/// Local data source for Assignment caching using Hive
abstract class AssignmentLocalDataSource {
  Future<List<AssignmentModel>> getCachedAssignments(String courseId);
  Future<void> cacheAssignments(String courseId, List<AssignmentModel> assignments);
  Future<void> clearCache();
  Future<void> clearCacheForCourse(String courseId);
}

/// Implementation of AssignmentLocalDataSource using Hive
class AssignmentLocalDataSourceImpl implements AssignmentLocalDataSource {
  static const String _boxName = 'assignmentBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  String _getKey(String courseId) => 'assignments_$courseId';

  @override
  Future<List<AssignmentModel>> getCachedAssignments(String courseId) async {
    try {
      final box = await _getBox();
      final cachedData = box.get(_getKey(courseId));

      if (cachedData != null && cachedData is List) {
        return cachedData
            .map(
              (item) {
                final map = Map<String, dynamic>.from(item);
                final id = map['id'] as String;
                return AssignmentModel.fromJson(map, id);
              },
            )
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheAssignments(String courseId, List<AssignmentModel> assignments) async {
    try {
      final box = await _getBox();
      final assignmentsJson = assignments.map((a) {
        final json = a.toJson();
        json['id'] = a.id; // Include ID in cached JSON
        return json;
      }).toList();
      await box.put(_getKey(courseId), assignmentsJson);
      // Store last sync timestamp
      await box.put('${_getKey(courseId)}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  @override
  Future<void> clearCacheForCourse(String courseId) async {
    try {
      final box = await _getBox();
      await box.delete(_getKey(courseId));
      await box.delete('${_getKey(courseId)}_timestamp');
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

  /// Get last sync timestamp for course assignments
  Future<DateTime?> getLastSyncTime(String courseId) async {
    try {
      final box = await _getBox();
      final timestamp = box.get('${_getKey(courseId)}_timestamp');
      if (timestamp != null && timestamp is String) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }
}
