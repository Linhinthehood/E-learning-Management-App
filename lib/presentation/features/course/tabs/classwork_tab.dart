import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/assignment_entity.dart';
import '../../../../domain/entities/quiz_entity.dart';
import '../../../../domain/entities/quiz_attempt_entity.dart';
import '../../../../domain/entities/material_entity.dart';
import '../../../../domain/entities/question_bank_entity.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/quiz_provider.dart';
import '../../../providers/material_provider.dart';
import '../../../providers/question_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/assignment_form_dialog.dart';
import '../widgets/quiz_form_dialog.dart';
import '../widgets/material_form_dialog.dart';
import '../widgets/question_bank_form_dialog.dart';
import '../question_bank_detail_screen.dart';
import '../widgets/assignment_submission_dialog.dart';
import '../quiz_taking_screen.dart';
import '../../../providers/quiz_attempt_provider.dart';
import '../../../providers/assignment_submission_provider.dart';
import '../../tracking/assignment_tracking_screen.dart';
import '../../tracking/quiz_tracking_screen.dart';
import '../../tracking/material_tracking_screen.dart';
import '../../../../services/file_download_service.dart';
import '../../../providers/view_tracking_provider.dart';
import '../screens/assignment_detail_screen.dart';
import '../screens/quiz_detail_screen.dart';
import '../screens/material_detail_screen.dart';
import '../../../../domain/entities/assignment_submission_entity.dart';

/// Classwork tab - displays assignments, quizzes, and materials in one unified view
class ClassworkTab extends ConsumerStatefulWidget {
  final CourseEntity course;
  final bool isReadOnly;
  final bool isStudent;

  const ClassworkTab({
    super.key,
    required this.course,
    this.isReadOnly = false,
    this.isStudent = false,
  });

  @override
  ConsumerState<ClassworkTab> createState() => _ClassworkTabState();
}

class _ClassworkTabState extends ConsumerState<ClassworkTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _filterType = 'All'; // All, Assignments, Quizzes, Materials, Question Banks
  String _filterStatus = 'All'; // All, Open, Closed, Upcoming
  String _sortBy = 'Date (Newest First)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(assignmentProvider.notifier).loadAssignments(widget.course.id);
        ref.read(quizProvider.notifier).loadQuizzes(widget.course.id);
        ref.read(materialProvider.notifier).loadMaterials(widget.course.id);
        if (!widget.isStudent) {
          ref.read(questionBankProvider.notifier).loadQuestionBanks(widget.course.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<dynamic> _applyFiltersAndSort(List<dynamic> items) {
    var filtered = items.where((item) {
      // Type filter
      if (_filterType != 'All') {
        String expectedType = '';
        switch (_filterType) {
          case 'Assignments':
            expectedType = 'assignment';
            break;
          case 'Quizzes':
            expectedType = 'quiz';
            break;
          case 'Materials':
            expectedType = 'material';
            break;
          case 'Question Banks':
            expectedType = 'question_bank';
            break;
        }
        if (item.type != expectedType) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        String title = '';
        String description = '';
        
        if (item.type == 'assignment') {
          title = item.assignment.title;
          description = item.assignment.description;
        } else if (item.type == 'quiz') {
          title = item.quiz.title;
          description = item.quiz.description;
        } else if (item.type == 'material') {
          title = item.material.title;
          description = item.material.description;
        } else if (item.type == 'question_bank') {
          title = item.questionBank.name;
          description = item.questionBank.description ?? '';
        }

        final matchesSearch = title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        if (!matchesSearch) return false;
      }

      // Status filter (for assignments and quizzes)
      if (_filterStatus != 'All') {
        if (item.type == 'assignment') {
          switch (_filterStatus) {
            case 'Open':
              if (!item.assignment.isOpen) return false;
              break;
            case 'Closed':
              if (!item.assignment.isClosed) return false;
              break;
            case 'Upcoming':
              if (!item.assignment.isUpcoming) return false;
              break;
          }
        } else if (item.type == 'quiz') {
          switch (_filterStatus) {
            case 'Open':
              if (!item.quiz.isOpen) return false;
              break;
            case 'Closed':
              if (!item.quiz.isClosed) return false;
              break;
            case 'Upcoming':
              if (!item.quiz.isUpcoming) return false;
              break;
          }
        } else {
          // Materials don't have status, so filter them out if status filter is active
          if (_filterStatus != 'All') return false;
        }
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      DateTime dateA, dateB;
      
      if (a.type == 'assignment') {
        dateA = a.assignment.deadline;
      } else if (a.type == 'quiz') {
        dateA = a.quiz.timeClose;
      } else if (a.type == 'material') {
        dateA = a.material.createdAt;
      } else {
        dateA = a.questionBank.createdAt;
      }

      if (b.type == 'assignment') {
        dateB = b.assignment.deadline;
      } else if (b.type == 'quiz') {
        dateB = b.quiz.timeClose;
      } else if (b.type == 'material') {
        dateB = b.material.createdAt;
      } else {
        dateB = b.questionBank.createdAt;
      }

      switch (_sortBy) {
        case 'Date (Newest First)':
          return dateB.compareTo(dateA);
        case 'Date (Oldest First)':
          return dateA.compareTo(dateB);
        case 'Title (A-Z)':
          String titleA = a.type == 'assignment' 
              ? a.assignment.title 
              : a.type == 'quiz' 
                  ? a.quiz.title 
                  : a.type == 'material'
                      ? a.material.title
                      : a.questionBank.name;
          String titleB = b.type == 'assignment' 
              ? b.assignment.title 
              : b.type == 'quiz' 
                  ? b.quiz.title 
                  : b.type == 'material'
                      ? b.material.title
                      : b.questionBank.name;
          return titleA.compareTo(titleB);
        case 'Title (Z-A)':
          String titleA = a.type == 'assignment' 
              ? a.assignment.title 
              : a.type == 'quiz' 
                  ? a.quiz.title 
                  : a.type == 'material'
                      ? a.material.title
                      : a.questionBank.name;
          String titleB = b.type == 'assignment' 
              ? b.assignment.title 
              : b.type == 'quiz' 
                  ? b.quiz.title 
                  : b.type == 'material'
                      ? b.material.title
                      : b.questionBank.name;
          return titleB.compareTo(titleA);
        default:
          return dateB.compareTo(dateA);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(assignmentProvider);
    final quizzesAsync = ref.watch(quizProvider);
    final materialsAsync = ref.watch(materialProvider);
    final questionBanksAsync = widget.isStudent 
        ? const AsyncValue.data(<QuestionBankEntity>[])
        : ref.watch(questionBankProvider);

    return assignmentsAsync.when(
      data: (assignments) => quizzesAsync.when(
        data: (quizzes) => materialsAsync.when(
          data: (materials) => questionBanksAsync.when(
            data: (questionBanks) {
              // Combine all items
              final allItems = [
                ...assignments.map((a) => _ClassworkItem(type: 'assignment', assignment: a)),
                ...quizzes.map((q) => _ClassworkItem(type: 'quiz', quiz: q)),
                ...materials.map((m) => _ClassworkItem(type: 'material', material: m)),
                if (!widget.isStudent)
                  ...questionBanks.map((qb) => _ClassworkItem(type: 'question_bank', questionBank: qb)),
              ];

            final filteredItems = _applyFiltersAndSort(allItems);

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Classwork',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!widget.isStudent && !widget.isReadOnly) ...[
                          const SizedBox(width: 8),
                          _buildAddButton(context),
                        ],
                      ],
                    ),
                  ),
                ),

                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search assignments, quizzes, materials...',
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
                ),

                // Filter and Sort controls
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        // Type filter
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _filterType,
                                isDense: true,
                                decoration: InputDecoration(
                                  labelText: 'Type',
                                  prefixIcon: const Icon(Icons.category, size: 20),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: [
                                  'All', 
                                  'Assignments', 
                                  'Quizzes', 
                                  'Materials',
                                  if (!widget.isStudent) 'Question Banks',
                                ].map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: GoogleFonts.inter(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _filterType = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _filterStatus,
                                isDense: true,
                                decoration: InputDecoration(
                                  labelText: 'Status',
                                  prefixIcon: const Icon(Icons.filter_list, size: 20),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: ['All', 'Open', 'Closed', 'Upcoming'].map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: GoogleFonts.inter(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _filterStatus = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _sortBy,
                                isDense: true,
                                decoration: InputDecoration(
                                  labelText: 'Sort',
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: [
                                  'Date (Newest First)',
                                  'Date (Oldest First)',
                                  'Title (A-Z)',
                                  'Title (Z-A)',
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Items list
                if (filteredItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _filterType != 'All' || _filterStatus != 'All'
                                ? 'No items match your filters'
                                : 'No classwork yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _filterType != 'All' ||
                              _filterStatus != 'All') ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _filterType = 'All';
                                  _filterStatus = 'All';
                                });
                              },
                              child: Text(
                                'Clear filters',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.buttonPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredItems[index];
                          if (item.type == 'assignment') {
                            return _buildAssignmentCard(context, ref, item.assignment);
                          } else if (item.type == 'quiz') {
                            return _buildQuizCard(context, ref, item.quiz);
                          } else if (item.type == 'material') {
                            return _buildMaterialCard(context, ref, item.material);
                          } else {
                            return _buildQuestionBankCard(context, ref, item.questionBank);
                          }
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, _) => CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading question banks'),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(questionBankProvider.notifier).loadQuestionBanks(widget.course.id);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
          loading: () => CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
          error: (error, _) => CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading materials'),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(materialProvider.notifier).loadMaterials(widget.course.id);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
        error: (error, _) => CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading quizzes'),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(quizProvider.notifier).loadQuizzes(widget.course.id);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading assignments'),
              ElevatedButton(
                onPressed: () {
                  ref.read(assignmentProvider.notifier).loadAssignments(widget.course.id);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.buttonPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Add',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'assignment',
          child: Row(
            children: [
              Icon(Icons.assignment, size: 20),
              SizedBox(width: 8),
              Text('Assignment'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'quiz',
          child: Row(
            children: [
              Icon(Icons.quiz, size: 20),
              SizedBox(width: 8),
              Text('Quiz'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'material',
          child: Row(
            children: [
              Icon(Icons.folder, size: 20),
              SizedBox(width: 8),
              Text('Material'),
            ],
          ),
        ),
        if (!widget.isStudent)
          const PopupMenuItem(
            value: 'question_bank',
            child: Row(
              children: [
                Icon(Icons.library_books, size: 20),
                SizedBox(width: 8),
                Text('Question Bank'),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'assignment') {
          _showAssignmentDialog(context, ref, null);
        } else if (value == 'quiz') {
          _showQuizDialog(context, ref, null);
        } else if (value == 'material') {
          _showMaterialDialog(context, ref, null);
        } else if (value == 'question_bank') {
          _showQuestionBankDialog(context, ref, null);
        }
      },
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    WidgetRef ref,
    AssignmentEntity assignment,
  ) {
    final userAsync = ref.read(authProvider);
    final isAuthor = userAsync.value?.uid == widget.course.instructorId;
    final currentUserId = userAsync.value?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isAuthor) {
            // Instructor: show edit dialog
            _showAssignmentDialog(context, ref, assignment);
          } else {
            // Student: navigate to detail screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AssignmentDetailScreen(
                  course: widget.course,
                  assignment: assignment,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, size: 20, color: AppColors.buttonPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _showAssignmentDialog(context, ref, assignment);
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.analytics, size: 18),
                            SizedBox(width: 8),
                            Text('View Tracking'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AssignmentTrackingScreen(
                                  course: widget.course,
                                  assignment: assignment,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _deleteAssignment(context, ref, assignment);
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: assignment.isOpen
                        ? Colors.green.withValues(alpha: 0.1)
                        : assignment.isClosed
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    assignment.isOpen
                        ? 'Open'
                        : assignment.isClosed
                            ? 'Closed'
                            : 'Upcoming',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: assignment.isOpen
                          ? Colors.green
                          : assignment.isClosed
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Deadline: ${_formatDateTime(assignment.deadline)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            // Student submission section
            if (!isAuthor && currentUserId != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              FutureBuilder<AssignmentSubmissionEntity?>(
                future: ref
                    .read(assignmentSubmissionProvider.notifier)
                    .getLatestSubmission(assignment.id, currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final latestSubmission = snapshot.data;
                  final attemptCount = latestSubmission?.attemptNumber ?? 0;
                  final canSubmit =
                      assignment.hasUnlimitedAttempts ||
                      attemptCount < assignment.maxAttempts;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Submission status
                      _buildSubmissionStatus(latestSubmission, attemptCount, assignment),
                      const SizedBox(height: 12),

                      // Submit button
                      if (canSubmit && assignment.isOpen && !assignment.isClosed)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showSubmissionDialog(
                              context,
                              ref,
                              assignment,
                              attemptCount + 1,
                            ),
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: Text(
                              attemptCount == 0
                                  ? 'Submit Assignment'
                                  : 'Edit Submission (Attempt ${attemptCount + 1})',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        )
                      else if (!canSubmit)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Maximum attempts reached',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, WidgetRef ref, QuizEntity quiz) {
    final userAsync = ref.read(authProvider);
    final isAuthor = userAsync.value?.uid == widget.course.instructorId;
    final currentUserId = userAsync.value?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isAuthor) {
            // Instructor: show edit dialog
            _showQuizDialog(context, ref, quiz);
          } else {
            // Student: navigate to detail screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QuizDetailScreen(
                  course: widget.course,
                  quiz: quiz,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.quiz, size: 20, color: AppColors.buttonPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quiz.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _showQuizDialog(context, ref, quiz);
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.analytics, size: 18),
                            SizedBox(width: 8),
                            Text('View Tracking'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => QuizTrackingScreen(
                                  course: widget.course,
                                  quiz: quiz,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _deleteQuiz(context, ref, quiz);
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: quiz.isOpen
                        ? Colors.green.withValues(alpha: 0.1)
                        : quiz.isClosed
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quiz.isOpen
                        ? 'Open'
                        : quiz.isClosed
                            ? 'Closed'
                            : 'Upcoming',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: quiz.isOpen
                          ? Colors.green
                          : quiz.isClosed
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Closes: ${_formatDateTime(quiz.timeClose)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            // Student quiz attempt section
            if (!isAuthor && currentUserId != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              FutureBuilder<QuizAttemptEntity?>(
                future: ref
                    .read(quizAttemptProvider.notifier)
                    .getBestAttempt(quiz.id, currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final bestAttempt = snapshot.data;

                  return FutureBuilder<int>(
                    future: ref
                        .read(quizAttemptProvider.notifier)
                        .countStudentAttempts(quiz.id, currentUserId),
                    builder: (context, countSnapshot) {
                      final attemptCount = countSnapshot.data ?? 0;
                      final canTake =
                          quiz.hasUnlimitedAttempts ||
                          attemptCount < quiz.numAttempts;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Attempt status (showing best score)
                          _buildAttemptStatus(bestAttempt, attemptCount, quiz),
                          // Show attempts count if multiple attempts
                          if (attemptCount > 1) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.buttonPrimary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 16,
                                    color: AppColors.buttonPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Total attempts: $attemptCount',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.buttonPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(Best score shown above)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Take quiz button
                          if (canTake && quiz.isOpen && !quiz.isClosed)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _startQuiz(
                                  context,
                                  ref,
                                  quiz,
                                  currentUserId,
                                ),
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: Text(
                                  attemptCount == 0
                                      ? 'Start Quiz'
                                      : bestAttempt?.isInProgress == true
                                      ? 'Continue Quiz'
                                      : 'Start Attempt ${attemptCount + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            )
                          else if (!canTake)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Maximum attempts reached',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMaterialCard(
    BuildContext context,
    WidgetRef ref,
    MaterialEntity material,
  ) {
    final userAsync = ref.read(authProvider);
    final isAuthor = userAsync.value?.uid == widget.course.instructorId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isAuthor) {
            // Instructor: show edit dialog
            _showMaterialDialog(context, ref, material);
          } else {
            // Student: navigate to detail screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MaterialDetailScreen(
                  course: widget.course,
                  material: material,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder, size: 20, color: AppColors.buttonPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      material.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _showMaterialDialog(context, ref, material);
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.analytics, size: 18),
                            SizedBox(width: 8),
                            Text('View Tracking'),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MaterialTrackingScreen(
                                  course: widget.course,
                                  material: material,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _deleteMaterial(context, ref, material);
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${material.files.length} file(s)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (material.files.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: material.files.map((file) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          file.isExternalLink ? Icons.link : Icons.attach_file,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            file.name,
                            style: GoogleFonts.inter(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Open button
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () => _openFile(context, file.url),
                          tooltip: 'Open file',
                        ),
                        // Download button
                        IconButton(
                          icon: const Icon(Icons.download, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () => _downloadFile(
                            context,
                            ref,
                            material.id,
                            file.url,
                            file.name,
                          ),
                          tooltip: 'Download file',
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildQuestionBankCard(
    BuildContext context,
    WidgetRef ref,
    QuestionBankEntity questionBank,
  ) {
    final userAsync = ref.read(authProvider);
    final isAuthor = userAsync.value?.uid == widget.course.instructorId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => QuestionBankDetailScreen(questionBank: questionBank),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.library_books, size: 20, color: AppColors.buttonPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      questionBank.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _showQuestionBankDialog(context, ref, questionBank);
                            });
                          },
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () {
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _deleteQuestionBank(context, ref, questionBank);
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${_formatDate(questionBank.createdAt)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAssignmentDialog(
    BuildContext context,
    WidgetRef ref,
    AssignmentEntity? assignment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AssignmentFormDialog(
        course: widget.course,
        assignment: assignment,
      ),
    ).then((success) {
      if (mounted && success == true) {
        ref.read(assignmentProvider.notifier).loadAssignments(widget.course.id);
      }
    });
  }

  void _showQuizDialog(BuildContext context, WidgetRef ref, QuizEntity? quiz) {
    showDialog(
      context: context,
      builder: (context) => QuizFormDialog(course: widget.course, quiz: quiz),
    ).then((success) {
      if (mounted && success == true) {
        ref.read(quizProvider.notifier).loadQuizzes(widget.course.id);
      }
    });
  }

  void _showMaterialDialog(
    BuildContext context,
    WidgetRef ref,
    MaterialEntity? material,
  ) {
    showDialog(
      context: context,
      builder: (context) => MaterialFormDialog(
        course: widget.course,
        material: material,
      ),
    ).then((success) {
      if (mounted && success == true) {
        ref.read(materialProvider.notifier).loadMaterials(widget.course.id);
      }
    });
  }

  void _showQuestionBankDialog(
    BuildContext context,
    WidgetRef ref,
    QuestionBankEntity? questionBank,
  ) {
    showDialog(
      context: context,
      builder: (context) => QuestionBankFormDialog(
        course: widget.course,
        questionBank: questionBank,
      ),
    ).then((success) {
      if (mounted && success == true) {
        ref.read(questionBankProvider.notifier).loadQuestionBanks(widget.course.id);
      }
    });
  }

  void _deleteQuestionBank(
    BuildContext context,
    WidgetRef ref,
    QuestionBankEntity questionBank,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Question Bank', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${questionBank.name}"? This will also delete all questions in this bank.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(questionBankProvider.notifier).deleteQuestionBank(questionBank.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${questionBank.name} deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteAssignment(
    BuildContext context,
    WidgetRef ref,
    AssignmentEntity assignment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Assignment', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${assignment.title}"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(assignmentProvider.notifier).deleteAssignment(assignment.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${assignment.title} deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteQuiz(BuildContext context, WidgetRef ref, QuizEntity quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Quiz', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${quiz.title}"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(quizProvider.notifier).deleteQuiz(quiz.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${quiz.title} deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteMaterial(
    BuildContext context,
    WidgetRef ref,
    MaterialEntity material,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Material', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${material.title}"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(materialProvider.notifier).deleteMaterial(material.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${material.title} deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionStatus(
    AssignmentSubmissionEntity? submission,
    int attemptCount,
    AssignmentEntity assignment,
  ) {
    if (submission == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_actions, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              'Not submitted yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (submission.status == SubmissionStatus.graded) {
      statusColor = Colors.blue;
      statusIcon = Icons.grading;
      statusText = 'Graded: ${submission.grade?.toStringAsFixed(1)} points';
    } else if (submission.status == SubmissionStatus.late) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Submitted late (Attempt $attemptCount)';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Submitted on time (Attempt $attemptCount)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (submission.status == SubmissionStatus.graded &&
              submission.feedback != null &&
              submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Feedback:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              submission.feedback!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Submitted: ${_formatDateTime(submission.submissionTime)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDialog(
    BuildContext context,
    WidgetRef ref,
    AssignmentEntity assignment,
    int attemptNumber,
  ) {
    showDialog(
      context: context,
      builder: (context) => AssignmentSubmissionDialog(
        assignment: assignment,
        attemptNumber: attemptNumber,
      ),
    ).then((success) {
      if (mounted && success == true) {
        ref.read(assignmentProvider.notifier).loadAssignments(widget.course.id);
        setState(() {}); // Refresh UI to show updated submission status
      }
    });
  }

  Future<void> _startQuiz(
    BuildContext context,
    WidgetRef ref,
    QuizEntity quiz,
    String studentId,
  ) async {
    final inProgressAttempt = await ref
        .read(quizAttemptProvider.notifier)
        .getInProgressAttempt(quiz.id, studentId);

    if (!mounted) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizTakingScreen(quiz: quiz, existingAttempt: inProgressAttempt),
      ),
    );

    if (result == true && mounted) {
      ref.read(quizProvider.notifier).loadQuizzes(widget.course.id);
    }
  }

  Widget _buildAttemptStatus(
    QuizAttemptEntity? attempt,
    int attemptCount,
    QuizEntity quiz,
  ) {
    if (attempt == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            const Icon(Icons.quiz, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              'Not attempted yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (attempt.isGraded) {
      statusColor = Colors.blue;
      statusIcon = Icons.grading;
      final percentage = attempt.percentage ?? 0;
      statusText =
          'Graded: ${attempt.score?.toStringAsFixed(1)}/${attempt.maxScore} (${percentage.toStringAsFixed(1)}%)';
    } else if (attempt.isInProgress) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Quiz in progress (Attempt $attemptCount)';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      final percentage = attempt.percentage ?? 0;
      statusText =
          'Completed: ${attempt.score?.toStringAsFixed(1)}/${attempt.maxScore} (${percentage.toStringAsFixed(1)}%)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (attempt.feedback != null && attempt.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Feedback:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              attempt.feedback!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (attempt.endTime != null) ...[
            const SizedBox(height: 8),
            Text(
              'Submitted: ${_formatDateTime(attempt.endTime!)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String fileUrl) async {
    final downloadService = FileDownloadService();

    try {
      await downloadService.openFile(fileUrl: fileUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(
    BuildContext context,
    WidgetRef ref,
    String materialId,
    String fileUrl,
    String fileName,
  ) async {
    final downloadService = FileDownloadService();

    try {
      // Track download
      await ref
          .read(
            viewTrackingByContentProvider((
              contentId: materialId,
              contentType: 'material',
            )).notifier,
          )
          .trackDownload();

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Downloading $fileName...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Download file
      await downloadService.downloadFile(fileUrl: fileUrl, fileName: fileName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.contains('untrusted')
                  ? 'Cannot download: Cloudinary account needs verification. Use "Open" to view file.'
                  : 'Failed to download file: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

class _ClassworkItem {
  final String type;
  final AssignmentEntity? assignment;
  final QuizEntity? quiz;
  final MaterialEntity? material;
  final QuestionBankEntity? questionBank;

  _ClassworkItem({
    required this.type,
    this.assignment,
    this.quiz,
    this.material,
    this.questionBank,
  });
}

