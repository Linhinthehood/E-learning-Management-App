import 'package:hive_flutter/hive_flutter.dart';

/// Initialize Hive for offline storage
class HiveInitializer {
  static Future<void> initialize() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Open boxes
    await Hive.openBox('userBox');
    await Hive.openBox('settingsBox');
    await Hive.openBox('semesterBox');
    await Hive.openBox('courseBox');
    await Hive.openBox('materialBox');
    await Hive.openBox('assignmentBox');
  }

  /// Clear all Hive data (useful for logout)
  static Future<void> clearAll() async {
    await Hive.box('userBox').clear();
    await Hive.box('settingsBox').clear();
    await Hive.box('semesterBox').clear();
    await Hive.box('courseBox').clear();
    await Hive.box('materialBox').clear();
    await Hive.box('assignmentBox').clear();
  }
}
