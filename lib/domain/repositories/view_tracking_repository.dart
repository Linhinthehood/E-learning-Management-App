import '../entities/view_tracking_entity.dart';

/// Repository interface for view tracking
abstract class ViewTrackingRepository {
  /// Track a view or download action
  Future<void> trackAction({
    required String contentId,
    required String contentType,
    required String action,
  });

  /// Get tracking records for a specific content
  Future<List<ViewTrackingEntity>> getTrackingByContentId(
    String contentId,
    String contentType,
  );

  /// Get tracking records for a specific student
  Future<List<ViewTrackingEntity>> getTrackingByStudentId(
    String studentId,
  );

  /// Check if a student has viewed specific content
  Future<bool> hasStudentViewed(
    String studentId,
    String contentId,
    String contentType,
  );
}
