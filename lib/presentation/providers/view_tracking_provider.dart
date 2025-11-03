import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/view_tracking_entity.dart';
import '../../domain/repositories/view_tracking_repository.dart';
import '../../data/repositories/view_tracking_repository_impl.dart';

/// Provider for view tracking repository
final viewTrackingRepositoryProvider = Provider<ViewTrackingRepository>((ref) {
  return ViewTrackingRepositoryImpl();
});

/// Provider for view tracking by content ID
final viewTrackingByContentProvider = StateNotifierProvider.family<
    ViewTrackingNotifier,
    AsyncValue<List<ViewTrackingEntity>>,
    ({String contentId, String contentType})>((ref, params) {
  return ViewTrackingNotifier(
    ref.read(viewTrackingRepositoryProvider),
    params.contentId,
    params.contentType,
  );
});

/// View tracking notifier
class ViewTrackingNotifier
    extends StateNotifier<AsyncValue<List<ViewTrackingEntity>>> {
  final ViewTrackingRepository _repository;
  final String _contentId;
  final String _contentType;

  ViewTrackingNotifier(
    this._repository,
    this._contentId,
    this._contentType,
  ) : super(const AsyncValue.loading()) {
    loadTracking();
  }

  /// Load tracking data for content
  Future<void> loadTracking() async {
    state = const AsyncValue.loading();
    try {
      final tracking = await _repository.getTrackingByContentId(
        _contentId,
        _contentType,
      );
      state = AsyncValue.data(tracking);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Track a view action
  Future<void> trackView() async {
    try {
      await _repository.trackAction(
        contentId: _contentId,
        contentType: _contentType,
        action: 'view',
      );
      await loadTracking(); // Reload tracking data
    } catch (e) {
      // Silently fail - tracking shouldn't block the user
    }
  }

  /// Track a download action
  Future<void> trackDownload() async {
    try {
      await _repository.trackAction(
        contentId: _contentId,
        contentType: _contentType,
        action: 'download',
      );
      await loadTracking(); // Reload tracking data
    } catch (e) {
      // Silently fail - tracking shouldn't block the user
    }
  }
}
