import 'package:hive/hive.dart';
import '../models/semester_model.dart';

/// Local data source for Semester caching using Hive
abstract class SemesterLocalDataSource {
  Future<List<SemesterModel>> getCachedSemesters();
  Future<void> cacheSemesters(List<SemesterModel> semesters);
  Future<void> clearCache();
}

/// Implementation of SemesterLocalDataSource using Hive
class SemesterLocalDataSourceImpl implements SemesterLocalDataSource {
  static const String _boxName = 'semesterBox';
  static const String _key = 'semesters';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  @override
  Future<List<SemesterModel>> getCachedSemesters() async {
    try {
      final box = await _getBox();
      final cachedData = box.get(_key);

      if (cachedData != null && cachedData is List) {
        return cachedData
            .map(
              (item) => SemesterModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheSemesters(List<SemesterModel> semesters) async {
    try {
      final box = await _getBox();
      final semestersJson = semesters.map((s) => s.toJson()).toList();
      await box.put(_key, semestersJson);
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.delete(_key);
    } catch (e) {
      // Silently fail
    }
  }
}
