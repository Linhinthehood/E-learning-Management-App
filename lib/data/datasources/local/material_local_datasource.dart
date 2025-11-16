import 'package:hive/hive.dart';
import '../models/material_model.dart';

/// Local data source for Material caching using Hive
abstract class MaterialLocalDataSource {
  Future<List<MaterialModel>> getCachedMaterials(String courseId);
  Future<void> cacheMaterials(String courseId, List<MaterialModel> materials);
  Future<void> clearCache();
  Future<void> clearCacheForCourse(String courseId);
}

/// Implementation of MaterialLocalDataSource using Hive
class MaterialLocalDataSourceImpl implements MaterialLocalDataSource {
  static const String _boxName = 'materialBox';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  String _getKey(String courseId) => 'materials_$courseId';

  @override
  Future<List<MaterialModel>> getCachedMaterials(String courseId) async {
    try {
      final box = await _getBox();
      final cachedData = box.get(_getKey(courseId));

      if (cachedData != null && cachedData is List) {
        return cachedData
            .map(
              (item) {
                final map = Map<String, dynamic>.from(item);
                final id = map['id'] as String;
                return MaterialModel.fromJson(map, id);
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
  Future<void> cacheMaterials(String courseId, List<MaterialModel> materials) async {
    try {
      final box = await _getBox();
      final materialsJson = materials.map((m) {
        final json = m.toJson();
        json['id'] = m.id; // Include ID in cached JSON
        return json;
      }).toList();
      await box.put(_getKey(courseId), materialsJson);
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

  /// Get last sync timestamp for course materials
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
