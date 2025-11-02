import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

/// Remote data source for announcements
/// Handles Firestore calls for announcements
abstract class AnnouncementRemoteDataSource {
  /// Get all announcements for a course
  Future<List<AnnouncementModel>> getAnnouncementsByCourse(String courseId);

  /// Get announcements for a specific group
  Future<List<AnnouncementModel>> getAnnouncementsByGroup(
    String courseId,
    String groupId,
  );

  /// Get a single announcement by ID
  Future<AnnouncementModel?> getAnnouncementById(String announcementId);

  /// Get recent announcements (last N days)
  Future<List<AnnouncementModel>> getRecentAnnouncements(
    String courseId,
    int days,
  );

  /// Create a new announcement
  Future<AnnouncementModel> createAnnouncement(AnnouncementModel announcement);

  /// Update an existing announcement
  Future<AnnouncementModel> updateAnnouncement(AnnouncementModel announcement);

  /// Delete an announcement
  Future<void> deleteAnnouncement(String announcementId);
}

/// Implementation of AnnouncementRemoteDataSource using Firestore
class AnnouncementRemoteDataSourceImpl implements AnnouncementRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<AnnouncementModel>> getAnnouncementsByCourse(
    String courseId,
  ) async {
    try {
      // Get all announcements for the course (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('announcements')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Sort by createdAt in memory
      final announcements = querySnapshot.docs
          .map((doc) => AnnouncementModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by createdAt descending
      announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return announcements;
    } catch (e) {
      throw Exception('Failed to get announcements: ${e.toString()}');
    }
  }

  @override
  Future<List<AnnouncementModel>> getAnnouncementsByGroup(
    String courseId,
    String groupId,
  ) async {
    try {
      // Get announcements for the course (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('announcements')
          .where('courseId', isEqualTo: courseId)
          .where('scopedGroupIds', arrayContains: groupId)
          .get();

      // Sort by createdAt in memory
      final announcements = querySnapshot.docs
          .map((doc) => AnnouncementModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by createdAt descending
      announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return announcements;
    } catch (e) {
      throw Exception('Failed to get group announcements: ${e.toString()}');
    }
  }

  @override
  Future<AnnouncementModel?> getAnnouncementById(String announcementId) async {
    try {
      final docSnapshot = await _firestore
          .collection('announcements')
          .doc(announcementId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return AnnouncementModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get announcement: ${e.toString()}');
    }
  }

  @override
  Future<List<AnnouncementModel>> getRecentAnnouncements(
    String courseId,
    int days,
  ) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      // Get all announcements for the course
      final querySnapshot = await _firestore
          .collection('announcements')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Filter and sort in memory to avoid index requirement
      final announcements = querySnapshot.docs
          .map((doc) => AnnouncementModel.fromJson(doc.data(), doc.id))
          .where((announcement) => announcement.createdAt.isAfter(cutoffDate))
          .toList();

      // Sort by createdAt descending
      announcements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return announcements;
    } catch (e) {
      throw Exception('Failed to get recent announcements: ${e.toString()}');
    }
  }

  @override
  Future<AnnouncementModel> createAnnouncement(
    AnnouncementModel announcement,
  ) async {
    try {
      final docRef = await _firestore
          .collection('announcements')
          .add(announcement.toJson());

      final docSnapshot = await docRef.get();
      return AnnouncementModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create announcement: ${e.toString()}');
    }
  }

  @override
  Future<AnnouncementModel> updateAnnouncement(
    AnnouncementModel announcement,
  ) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(announcement.id)
          .update(announcement.toJson());

      return announcement;
    } catch (e) {
      throw Exception('Failed to update announcement: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).delete();
    } catch (e) {
      throw Exception('Failed to delete announcement: ${e.toString()}');
    }
  }
}
