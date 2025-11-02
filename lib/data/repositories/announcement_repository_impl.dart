import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/i_announcement_repository.dart';
import '../datasources/remote/announcement_remote_datasource.dart';
import '../datasources/models/announcement_model.dart';

/// Implementation of IAnnouncementRepository
/// Handles conversion between models and entities
class AnnouncementRepositoryImpl implements IAnnouncementRepository {
  final AnnouncementRemoteDataSource remoteDataSource;

  AnnouncementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AnnouncementEntity>> getAnnouncementsByCourse(
    String courseId,
  ) async {
    try {
      final announcementModels = await remoteDataSource
          .getAnnouncementsByCourse(courseId);
      return announcementModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AnnouncementEntity>> getAnnouncementsByGroup(
    String courseId,
    String groupId,
  ) async {
    try {
      final announcementModels = await remoteDataSource.getAnnouncementsByGroup(
        courseId,
        groupId,
      );
      return announcementModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AnnouncementEntity?> getAnnouncementById(String announcementId) async {
    try {
      final announcementModel = await remoteDataSource.getAnnouncementById(
        announcementId,
      );
      return announcementModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AnnouncementEntity> createAnnouncement(
    AnnouncementEntity announcement,
  ) async {
    try {
      final announcementModel = AnnouncementModel.fromEntity(announcement);
      final createdModel = await remoteDataSource.createAnnouncement(
        announcementModel,
      );
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AnnouncementEntity> updateAnnouncement(
    AnnouncementEntity announcement,
  ) async {
    try {
      final announcementModel = AnnouncementModel.fromEntity(announcement);
      final updatedModel = await remoteDataSource.updateAnnouncement(
        announcementModel,
      );
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await remoteDataSource.deleteAnnouncement(announcementId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AnnouncementEntity>> getRecentAnnouncements(
    String courseId,
    int days,
  ) async {
    try {
      final announcementModels = await remoteDataSource.getRecentAnnouncements(
        courseId,
        days,
      );
      return announcementModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }
}
