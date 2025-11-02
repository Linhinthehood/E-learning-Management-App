import '../entities/announcement_entity.dart';

/// Announcement repository interface
/// This defines the contract that data layer must implement
abstract class IAnnouncementRepository {
  /// Get all announcements for a course
  Future<List<AnnouncementEntity>> getAnnouncementsByCourse(String courseId);

  /// Get announcements for a specific group
  Future<List<AnnouncementEntity>> getAnnouncementsByGroup(
    String courseId,
    String groupId,
  );

  /// Get a single announcement by ID
  Future<AnnouncementEntity?> getAnnouncementById(String announcementId);

  /// Create a new announcement
  Future<AnnouncementEntity> createAnnouncement(AnnouncementEntity announcement);

  /// Update an existing announcement
  Future<AnnouncementEntity> updateAnnouncement(AnnouncementEntity announcement);

  /// Delete an announcement
  Future<void> deleteAnnouncement(String announcementId);

  /// Get recent announcements (last N days)
  Future<List<AnnouncementEntity>> getRecentAnnouncements(
    String courseId,
    int days,
  );
}
