/// View tracking entity for announcements and materials
class ViewTrackingEntity {
  final String id;
  final String contentId; // ID of announcement or material
  final String contentType; // 'announcement' or 'material'
  final String studentId;
  final String studentName;
  final String action; // 'view' or 'download'
  final DateTime timestamp;

  const ViewTrackingEntity({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.studentId,
    required this.studentName,
    required this.action,
    required this.timestamp,
  });

  /// Check if this is a view action
  bool get isView => action == 'view';

  /// Check if this is a download action
  bool get isDownload => action == 'download';

  /// Check if this is for an announcement
  bool get isAnnouncement => contentType == 'announcement';

  /// Check if this is for a material
  bool get isMaterial => contentType == 'material';
}
