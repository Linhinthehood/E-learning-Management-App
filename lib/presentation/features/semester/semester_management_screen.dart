import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/semester_entity.dart';
import '../../common/styles/colors.dart';
import '../../providers/semester_provider.dart';
import 'widgets/semester_form_dialog.dart';

class SemesterManagementScreen extends ConsumerStatefulWidget {
  const SemesterManagementScreen({super.key});

  @override
  ConsumerState<SemesterManagementScreen> createState() =>
      _SemesterManagementScreenState();
}

class _SemesterManagementScreenState
    extends ConsumerState<SemesterManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Start Date (Newest)';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SemesterEntity> _applyFiltersAndSort(List<SemesterEntity> semesters) {
    var filtered = semesters.where((semester) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            semester.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            semester.code.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;
      }
      return true;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Start Date (Newest)':
        filtered.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case 'Start Date (Oldest)':
        filtered.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case 'Name (A-Z)':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name (Z-A)':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Duration (Short-Long)':
        filtered.sort((a, b) => a.durationInDays.compareTo(b.durationInDays));
        break;
      case 'Duration (Long-Short)':
        filtered.sort((a, b) => b.durationInDays.compareTo(a.durationInDays));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final semesterState = ref.watch(semesterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semester Management',
                        style: GoogleFonts.inter(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage academic semesters',
                        style: GoogleFonts.inter(
                          fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showSemesterDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    MediaQuery.of(context).size.width < 600 ? 'Add' : 'Add Semester',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search semesters by name or code...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sort control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _sortBy,
              decoration: InputDecoration(
                labelText: 'Sort by',
                prefixIcon: const Icon(Icons.sort, size: 20),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              items:
                  [
                    'Start Date (Newest)',
                    'Start Date (Oldest)',
                    'Name (A-Z)',
                    'Name (Z-A)',
                    'Duration (Short-Long)',
                    'Duration (Long-Short)',
                  ].map((sortOption) {
                    return DropdownMenuItem(
                      value: sortOption,
                      child: Text(
                        sortOption,
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: semesterState.when(
                data: (semesters) {
                  final filteredSemesters = _applyFiltersAndSort(semesters);

                  if (semesters.isEmpty) {
                    return _buildEmptyState(context, ref);
                  }

                  if (filteredSemesters.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No semesters found',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildSemesterList(context, ref, filteredSemesters);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(context, ref, error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No semesters yet',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first semester to get started',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showSemesterDialog(context, ref),
            icon: const Icon(Icons.add),
            label: Text(
              'Add Semester',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Error loading semesters',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(semesterProvider.notifier).loadSemesters(),
            icon: const Icon(Icons.refresh),
            label: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterList(
    BuildContext context,
    WidgetRef ref,
    List<SemesterEntity> semesters,
  ) {
    return ListView.separated(
      itemCount: semesters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final semester = semesters[index];
        return _buildSemesterCard(context, ref, semester);
      },
    );
  }

  Widget _buildSemesterCard(
    BuildContext context,
    WidgetRef ref,
    SemesterEntity semester,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isActive = semester.isActive;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.buttonPrimary : AppColors.border,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Left side - Semester info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        semester.name,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.buttonPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.buttonPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Code: ${semester.code}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${dateFormat.format(semester.startDate)} - ${dateFormat.format(semester.endDate)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${semester.durationInDays} days',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right side - Actions
          Row(
            children: [
              IconButton(
                onPressed: () => _showSemesterDialog(context, ref, semester),
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.textPrimary,
                tooltip: 'Edit',
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    _showDeleteConfirmation(context, ref, semester),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSemesterDialog(
    BuildContext context,
    WidgetRef ref, [
    SemesterEntity? semester,
  ]) {
    showDialog(
      context: context,
      builder: (context) => SemesterFormDialog(semester: semester),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    SemesterEntity semester,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Delete Semester',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${semester.name}"? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(semesterProvider.notifier)
                    .deleteSemester(semester.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Semester deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
