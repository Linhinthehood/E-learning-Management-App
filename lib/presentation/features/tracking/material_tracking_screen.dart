import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../common/styles/colors.dart';
import '../../../domain/entities/course_entity.dart';
import '../../../domain/entities/material_entity.dart';
import '../../../domain/entities/view_tracking_entity.dart';
import '../../../domain/entities/enrollment_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/view_tracking_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../../utils/services/csv_export_service.dart';
import '../../../utils/helpers/file_download_helper.dart';

/// Material Tracking Screen - shows who downloaded materials
class MaterialTrackingScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final MaterialEntity material;

  const MaterialTrackingScreen({
    super.key,
    required this.course,
    required this.material,
  });

  @override
  ConsumerState<MaterialTrackingScreen> createState() =>
      _MaterialTrackingScreenState();
}

class _MaterialTrackingScreenState
    extends ConsumerState<MaterialTrackingScreen> {
  String _filter = 'all'; // 'all', 'downloaded', 'not_downloaded'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enrollmentProvider.notifier).loadEnrollments(widget.course.id);
      ref.read(studentsProvider.notifier).loadStudents();
      ref
          .read(
            viewTrackingByContentProvider((
              contentId: widget.material.id,
              contentType: 'material',
            )).notifier,
          )
          .loadTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enrollmentsAsync = ref.watch(enrollmentProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final trackingAsync = ref.watch(
      viewTrackingByContentProvider((
        contentId: widget.material.id,
        contentType: 'material',
      )),
    );

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
              'Material Tracking',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.material.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.textPrimary),
            onPressed: () => _exportToCsv(context, ref),
            tooltip: 'Export to CSV',
          ),
        ],
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
                _buildFilterChip('Downloaded', 'downloaded'),
                const SizedBox(width: 8),
                _buildFilterChip('Not Downloaded', 'not_downloaded'),
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
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                error.toString(),
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: () {
                                ref
                                    .read(
                                      viewTrackingByContentProvider((
                                        contentId: widget.material.id,
                                        contentType: 'material',
                                      )).notifier,
                                    )
                                    .loadTracking();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading students: ${error.toString()}',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
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

    // Create a map of studentId -> download tracking
    final downloadMap = <String, ViewTrackingEntity>{};
    for (var tracking in trackings) {
      if (tracking.isDownload) {
        final existing = downloadMap[tracking.studentId];
        if (existing == null ||
            tracking.timestamp.isAfter(existing.timestamp)) {
          downloadMap[tracking.studentId] = tracking;
        }
      }
    }

    // Build student tracking list
    final studentTrackingList = <_StudentTrackingData>[];
    for (var enrollment in enrollments) {
      final student = studentMap[enrollment.studentId];
      final tracking = downloadMap[enrollment.studentId];
      studentTrackingList.add(
        _StudentTrackingData(
          studentId: enrollment.studentId,
          studentName: student?.displayName ?? 'Unknown',
          tracking: tracking,
        ),
      );
    }

    // Apply filter
    final filteredList = studentTrackingList.where((item) {
      switch (_filter) {
        case 'downloaded':
          return item.tracking != null;
        case 'not_downloaded':
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
              Icons.folder_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _filter == 'downloaded'
                  ? 'No students have downloaded this material'
                  : _filter == 'not_downloaded'
                  ? 'All students have downloaded this material'
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
    final hasDownloaded = item.tracking != null;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasDownloaded
              ? Colors.green.withValues(alpha: 0.2)
              : AppColors.textSecondary.withValues(alpha: 0.2),
          child: Icon(
            hasDownloaded ? Icons.download_done : Icons.download_outlined,
            color: hasDownloaded ? Colors.green : AppColors.textSecondary,
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
            ? Text(
                'Downloaded: ${dateFormat.format(item.tracking!.timestamp)}',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              )
            : Text(
                'Not downloaded',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
        trailing: hasDownloaded
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.circle_outlined, color: AppColors.textSecondary),
      ),
    );
  }

  /// Export material downloads to CSV
  Future<void> _exportToCsv(BuildContext context, WidgetRef ref) async {
    // Get data from providers
    final enrollmentsAsync = ref.read(enrollmentProvider);
    final studentsAsync = ref.read(studentsProvider);
    final trackingAsync = ref.read(
      viewTrackingByContentProvider((
        contentId: widget.material.id,
        contentType: 'material',
      )),
    );

    // Check if all data is loaded
    if (enrollmentsAsync.isLoading ||
        studentsAsync.isLoading ||
        trackingAsync.isLoading) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for data to load'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (enrollmentsAsync.hasError ||
        studentsAsync.hasError ||
        trackingAsync.hasError) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final enrollments = enrollmentsAsync.value ?? [];
    final students = studentsAsync.value ?? [];
    final trackings = trackingAsync.value ?? [];

    try {
      // Create student map
      final studentMap = <String, UserEntity>{};
      for (var student in students) {
        studentMap[student.uid] = student;
      }

      // Generate CSV content
      final csvContent = CsvExportService.exportMaterialDownloads(
        enrollments: enrollments,
        downloads: trackings,
        studentMap: studentMap,
      );

      // Generate filename with timestamp
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final timestamp = dateFormat.format(DateTime.now());
      final filename =
          'material_${widget.material.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}_$timestamp.csv';

      // Download file
      await FileDownloadHelper.downloadCsv(
        csvContent: csvContent,
        filename: filename,
        context: context,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
