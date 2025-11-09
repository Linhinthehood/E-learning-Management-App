import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../common/styles/colors.dart';
import '../../../domain/entities/course_entity.dart';
import '../../../domain/entities/announcement_entity.dart';
import '../../../domain/entities/view_tracking_entity.dart';
import '../../../domain/entities/enrollment_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/view_tracking_provider.dart';
import '../../providers/enrollment_provider.dart';

/// Announcement Tracking Screen - shows who viewed/downloaded announcements
class AnnouncementTrackingScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final AnnouncementEntity announcement;

  const AnnouncementTrackingScreen({
    super.key,
    required this.course,
    required this.announcement,
  });

  @override
  ConsumerState<AnnouncementTrackingScreen> createState() =>
      _AnnouncementTrackingScreenState();
}

class _AnnouncementTrackingScreenState
    extends ConsumerState<AnnouncementTrackingScreen> {
  String _filter = 'all'; // 'all', 'viewed', 'not_viewed'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enrollmentProvider.notifier).loadEnrollments(widget.course.id);
      ref
          .read(viewTrackingByContentProvider(
            (contentId: widget.announcement.id, contentType: 'announcement'),
          ).notifier)
          .loadTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentsAsync = ref.watch(enrollmentProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final trackingAsync = ref.watch(viewTrackingByContentProvider(
      (contentId: widget.announcement.id, contentType: 'announcement'),
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Announcement Tracking',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.announcement.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Viewed', 'viewed'),
                const SizedBox(width: 8),
                _buildFilterChip('Not Viewed', 'not_viewed'),
              ],
            ),
          ),
          // Tracking data
          Expanded(
            child: enrollmentsAsync.when(
              data: (enrollments) {
                return studentsAsync.when(
                  data: (students) {
                    return trackingAsync.when(
                      data: (trackings) {
                        return _buildTrackingList(
                          enrollments,
                          students,
                          trackings,
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading tracking data',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(viewTrackingByContentProvider(
                                      (
                                        contentId: widget.announcement.id,
                                        contentType: 'announcement'
                                      ),
                                    ).notifier)
                                    .loadTracking();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading students: ${error.toString()}',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading enrollments: ${error.toString()}',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
        }
      },
      selectedColor: AppColors.buttonPrimary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.buttonPrimary,
    );
  }

  Widget _buildTrackingList(
    List<EnrollmentEntity> enrollments,
    List<UserEntity> students,
    List<ViewTrackingEntity> trackings,
  ) {
    // Create a map of studentId -> UserEntity
    final studentMap = <String, UserEntity>{};
    for (var student in students) {
      studentMap[student.uid] = student;
    }

    // Create a map of studentId -> tracking data
    final trackingMap = <String, ViewTrackingEntity>{};
    for (var tracking in trackings) {
      if (tracking.isView || tracking.isDownload) {
        final existing = trackingMap[tracking.studentId];
        if (existing == null ||
            tracking.timestamp.isAfter(existing.timestamp)) {
          trackingMap[tracking.studentId] = tracking;
        }
      }
    }

    // Build student tracking list
    final studentTrackingList = <_StudentTrackingData>[];
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final tracking = trackingMap[enrollment.studentId];
      studentTrackingList.add(_StudentTrackingData(
        studentId: enrollment.studentId,
        studentName: student?.displayName ?? 'Unknown',
        tracking: tracking,
      ));
    }

    // Apply filter
    final filteredList = studentTrackingList.where((item) {
      switch (_filter) {
        case 'viewed':
          return item.tracking != null;
        case 'not_viewed':
          return item.tracking == null;
        default:
          return true;
      }
    }).toList();

    // Sort by student name
    filteredList.sort((a, b) => a.studentName.compareTo(b.studentName));

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _filter == 'viewed'
                  ? 'No students have viewed this announcement'
                  : _filter == 'not_viewed'
                      ? 'All students have viewed this announcement'
                      : 'No students enrolled',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return _buildStudentTrackingCard(item);
      },
    );
  }

  Widget _buildStudentTrackingCard(_StudentTrackingData item) {
    final hasViewed = item.tracking != null;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasViewed
              ? Colors.green.withValues(alpha: 0.2)
              : AppColors.textSecondary.withValues(alpha: 0.2),
          child: Icon(
            hasViewed ? Icons.check_circle : Icons.person_outline,
            color: hasViewed ? Colors.green : AppColors.textSecondary,
          ),
        ),
        title: Text(
          item.studentName,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: item.tracking != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Viewed: ${dateFormat.format(item.tracking!.timestamp)}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (item.tracking!.isDownload) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Downloaded attachment',
                      style: GoogleFonts.inter(
                        color: AppColors.buttonPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                'Not viewed',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
        trailing: hasViewed
            ? Icon(
                Icons.visibility,
                color: Colors.green,
              )
            : Icon(
                Icons.visibility_off,
                color: AppColors.textSecondary,
              ),
      ),
    );
  }
}

/// Helper class for student tracking data
class _StudentTrackingData {
  final String studentId;
  final String studentName;
  final ViewTrackingEntity? tracking;

  _StudentTrackingData({
    required this.studentId,
    required this.studentName,
    this.tracking,
  });
}

