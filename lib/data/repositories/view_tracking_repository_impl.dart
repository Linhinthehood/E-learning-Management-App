import '../../domain/entities/view_tracking_entity.dart';
import '../../domain/repositories/view_tracking_repository.dart';
import '../datasources/remote/view_tracking_remote_datasource.dart';

/// Implementation of view tracking repository
class ViewTrackingRepositoryImpl implements ViewTrackingRepository {
  final ViewTrackingRemoteDataSource _remoteDataSource;

  ViewTrackingRepositoryImpl({
    ViewTrackingRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
            remoteDataSource ?? ViewTrackingRemoteDataSource();

  @override
  Future<void> trackAction({
    required String contentId,
    required String contentType,
    required String action,
  }) async {
    try {
      await _remoteDataSource.trackAction(
        contentId: contentId,
        contentType: contentType,
        action: action,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ViewTrackingEntity>> getTrackingByContentId(
    String contentId,
    String contentType,
  ) async {
    try {
      final models = await _remoteDataSource.getTrackingByContentId(
        contentId,
        contentType,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ViewTrackingEntity>> getTrackingByStudentId(
    String studentId,
  ) async {
    try {
      final models = await _remoteDataSource.getTrackingByStudentId(studentId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> hasStudentViewed(
    String studentId,
    String contentId,
    String contentType,
  ) async {
    try {
      return await _remoteDataSource.hasStudentViewed(
        studentId,
        contentId,
        contentType,
      );
    } catch (e) {
      return false;
    }
  }
}
