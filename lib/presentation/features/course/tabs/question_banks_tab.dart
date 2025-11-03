import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/question_bank_entity.dart';
import '../../../providers/question_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/question_bank_form_dialog.dart';
import '../question_bank_detail_screen.dart';

/// Question Banks tab - displays and manages question banks
class QuestionBanksTab extends ConsumerStatefulWidget {
  final CourseEntity course;

  const QuestionBanksTab({super.key, required this.course});

  @override
  ConsumerState<QuestionBanksTab> createState() => _QuestionBanksTabState();
}

class _QuestionBanksTabState extends ConsumerState<QuestionBanksTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(questionBankProvider.notifier)
            .loadQuestionBanks(widget.course.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionBanksAsync = ref.watch(questionBankProvider);

    return questionBanksAsync.when(
      data: (questionBanks) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question Banks',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showQuestionBankDialog(context, ref, null),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(
                      'Add Question Bank',
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
            Expanded(
              child: questionBanks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No question banks yet',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a question bank to start adding questions',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: questionBanks.length,
                      itemBuilder: (context, index) {
                        final questionBank = questionBanks[index];
                        return _buildQuestionBankCard(
                          context,
                          ref,
                          questionBank,
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading question banks: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(questionBankProvider.notifier)
                    .loadQuestionBanks(widget.course.id);
              },
              child: const Text('Retry'),
            ),
          ],
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
      margin: const EdgeInsets.only(bottom: 16),
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
              builder: (context) =>
                  QuestionBankDetailScreen(questionBank: questionBank),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.library_books,
                              size: 24,
                              color: AppColors.buttonPrimary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                questionBank.name,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Created: ${_formatDateTime(questionBank.createdAt)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (questionBank.updatedAt != null) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.update,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Updated: ${_formatDateTime(questionBank.updatedAt!)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () {
                            final navigatorContext = context;
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                if (mounted && navigatorContext.mounted) {
                                  _showQuestionBankDialog(
                                    navigatorContext,
                                    ref,
                                    questionBank,
                                  );
                                }
                              },
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          onTap: () {
                            final navigatorContext = context;
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                if (mounted && navigatorContext.mounted) {
                                  _deleteQuestionBank(
                                    navigatorContext,
                                    ref,
                                    questionBank,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                questionBank.description ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
        ref
            .read(questionBankProvider.notifier)
            .loadQuestionBanks(widget.course.id);
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
        title: Text(
          'Delete Question Bank',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${questionBank.name}"? This will also delete all questions in this bank. This action cannot be undone.',
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
                await ref
                    .read(questionBankProvider.notifier)
                    .deleteQuestionBank(questionBank.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${questionBank.name} deleted successfully',
                      ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
