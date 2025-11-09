import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/announcement_remote_datasource.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/i_announcement_repository.dart';

/// Provider for announcement remote data source
final announcementRemoteDataSourceProvider =
    Provider<AnnouncementRemoteDataSource>((ref) {
      return AnnouncementRemoteDataSourceImpl();
    });

/// Provider for announcement repository
final announcementRepositoryProvider = Provider<IAnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(
    remoteDataSource: ref.read(announcementRemoteDataSourceProvider),
  );
});

/// Announcement state notifier - manages announcements for a course
class AnnouncementNotifier
    extends StateNotifier<AsyncValue<List<AnnouncementEntity>>> {
  final IAnnouncementRepository _repository;
  String? _currentCourseId;

  AnnouncementNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load announcements for a course
  Future<void> loadAnnouncements(String courseId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final announcements = await _repository.getAnnouncementsByCourse(
        courseId,
      );
      state = AsyncValue.data(announcements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load announcements for a specific group
  Future<void> loadGroupAnnouncements(String courseId, String groupId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final announcements = await _repository.getAnnouncementsByGroup(
        courseId,
        groupId,
      );
      state = AsyncValue.data(announcements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load recent announcements (last N days)
  Future<void> loadRecentAnnouncements(String courseId, int days) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final announcements = await _repository.getRecentAnnouncements(
        courseId,
        days,
      );
      state = AsyncValue.data(announcements);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new announcement
  /// Returns the created announcement with the generated ID
  Future<AnnouncementEntity> createAnnouncement(AnnouncementEntity announcement) async {
    try {
      final createdAnnouncement = await _repository.createAnnouncement(announcement);
      if (_currentCourseId != null) {
        await loadAnnouncements(_currentCourseId!); // Reload list
      }
      return createdAnnouncement;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing announcement
  Future<void> updateAnnouncement(AnnouncementEntity announcement) async {
    try {
      await _repository.updateAnnouncement(announcement);
      if (_currentCourseId != null) {
        await loadAnnouncements(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _repository.deleteAnnouncement(announcementId);
      if (_currentCourseId != null) {
        await loadAnnouncements(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current announcements
  Future<void> refresh() async {
    if (_currentCourseId != null) {
      await loadAnnouncements(_currentCourseId!);
    }
  }
}

/// Provider for announcement state notifier
final announcementProvider =
    StateNotifierProvider<
      AnnouncementNotifier,
      AsyncValue<List<AnnouncementEntity>>
    >((ref) {
      return AnnouncementNotifier(ref.read(announcementRepositoryProvider));
    });

/// Provider for fetching a single announcement by ID
final announcementByIdProvider =
    FutureProvider.family<AnnouncementEntity?, String>((
      ref,
      announcementId,
    ) async {
      final repository = ref.read(announcementRepositoryProvider);
      return await repository.getAnnouncementById(announcementId);
    });
