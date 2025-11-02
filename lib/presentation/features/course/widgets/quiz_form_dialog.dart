import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/entities/quiz_entity.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/quiz_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/question_provider.dart';

/// Dialog for creating or editing a quiz
class QuizFormDialog extends ConsumerStatefulWidget {
  final CourseEntity course;
  final QuizEntity? quiz;

  const QuizFormDialog({super.key, required this.course, this.quiz});

  @override
  ConsumerState<QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends ConsumerState<QuizFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _timeOpen;
  DateTime? _timeClose;
  int _durationMinutes = 0; // 0 = no limit
  int _numAttempts = 1;
  final List<String> _selectedGroupIds = [];
  bool _isForAllGroups = true;
  bool _shuffleQuestions = false;
  bool _shuffleAnswers = false;
  bool _isLoading = false;

  // Quiz structure fields
  String? _selectedQuestionBankId;
  int _numQuestions = 10;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.quiz?.description ?? '',
    );
    _timeOpen = widget.quiz?.timeOpen ?? DateTime.now();
    _timeClose =
        widget.quiz?.timeClose ?? DateTime.now().add(const Duration(days: 7));
    _durationMinutes = widget.quiz?.durationMinutes ?? 0;
    _numAttempts = widget.quiz?.numAttempts ?? 1;
    _selectedGroupIds.addAll(widget.quiz?.scopedGroupIds ?? []);
    _isForAllGroups = widget.quiz?.isForAllGroups ?? true;
    _shuffleQuestions = widget.quiz?.shuffleQuestions ?? false;
    _shuffleAnswers = widget.quiz?.shuffleAnswers ?? false;

    // Initialize structure from existing quiz
    if (widget.quiz != null && widget.quiz!.structure.sections.isNotEmpty) {
      final section = widget.quiz!.structure.sections.first;
      _selectedQuestionBankId = section.questionBankId;
      _numQuestions = section.numQuestions;
    }

    // Load groups and question banks when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(groupProvider.notifier).loadGroups(widget.course.id);
        ref
            .read(questionBankProvider.notifier)
            .loadQuestionBanks(widget.course.id);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_timeOpen == null || _timeClose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select open and close times'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_timeClose!.isBefore(_timeOpen!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Close time must be after open time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedQuestionBankId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a question bank'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create quiz structure with a single section
      final structure = QuizStructure(
        sections: [
          QuizSection(
            name: 'Main Section',
            numQuestions: _numQuestions,
            questionBankId: _selectedQuestionBankId,
          ),
        ],
      );

      final quiz = QuizEntity(
        id: widget.quiz?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        courseId: widget.course.id,
        timeOpen: _timeOpen!,
        timeClose: _timeClose!,
        durationMinutes: _durationMinutes,
        numAttempts: _numAttempts,
        structure: structure,
        scopedGroupIds: _isForAllGroups ? [] : _selectedGroupIds,
        shuffleQuestions: _shuffleQuestions,
        shuffleAnswers: _shuffleAnswers,
        createdAt: widget.quiz?.createdAt ?? DateTime.now(),
      );

      if (widget.quiz == null) {
        await ref.read(quizProvider.notifier).createQuiz(quiz);
      } else {
        await ref.read(quizProvider.notifier).updateQuiz(quiz);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectOpenTime() async {
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _timeOpen ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timeOpen ?? DateTime.now()),
    );
    if (!mounted || time == null) return;
    setState(() {
      _timeOpen = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _selectCloseTime() async {
    if (!mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _timeClose ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _timeOpen ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted || picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timeClose ?? DateTime.now()),
    );
    if (!mounted || time == null) return;
    setState(() {
      _timeClose = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupProvider);
    final questionBanksAsync = ref.watch(questionBankProvider);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 900),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.quiz == null ? 'Create Quiz' : 'Edit Quiz',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Title *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Description *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.buttonPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Time Selection
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Open Time *',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectOpenTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _timeOpen != null
                                              ? '${_timeOpen!.day}/${_timeOpen!.month}/${_timeOpen!.year} ${_timeOpen!.hour}:${_timeOpen!.minute.toString().padLeft(2, '0')}'
                                              : 'Select open time',
                                          style: GoogleFonts.inter(),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Close Time *',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectCloseTime,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _timeClose != null
                                              ? '${_timeClose!.day}/${_timeClose!.month}/${_timeClose!.year} ${_timeClose!.hour}:${_timeClose!.minute.toString().padLeft(2, '0')}'
                                              : 'Select close time',
                                          style: GoogleFonts.inter(),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Duration
                      Text(
                        'Duration (minutes) *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              initialValue: _durationMinutes == 0
                                  ? ''
                                  : _durationMinutes.toString(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                hintText: '0 = no time limit',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _durationMinutes = int.tryParse(value) ?? 0;
                                });
                              },
                              validator: (value) {
                                final duration = int.tryParse(value ?? '');
                                if (duration == null || duration < 0) {
                                  return 'Must be 0 or greater';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _durationMinutes = 0; // No limit
                              });
                            },
                            child: const Text('No Limit (0)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Max Attempts
                      Text(
                        'Max Attempts *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              initialValue: _numAttempts.toString(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                hintText: '0 = unlimited',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _numAttempts = int.tryParse(value) ?? 1;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter max attempts';
                                }
                                final attempts = int.tryParse(value);
                                if (attempts == null || attempts < 0) {
                                  return 'Must be 0 or greater';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _numAttempts = 0; // Unlimited
                              });
                            },
                            child: const Text('Unlimited (0)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quiz Structure - Question Bank
                      Text(
                        'Question Bank *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      questionBanksAsync.when(
                        data: (questionBanks) {
                          if (questionBanks.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'No question banks available. Please create a question bank first.',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _selectedQuestionBankId,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.buttonPrimary,
                                  width: 2,
                                ),
                              ),
                            ),
                            items: questionBanks.map((bank) {
                              return DropdownMenuItem(
                                value: bank.id,
                                child: Text(bank.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedQuestionBankId = value;
                              });
                            },
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) =>
                            const Text('Error loading question banks'),
                      ),
                      const SizedBox(height: 24),

                      // Number of Questions
                      Text(
                        'Number of Questions *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        initialValue: _numQuestions.toString(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          hintText: 'Number of questions to show',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _numQuestions = int.tryParse(value) ?? 10;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number of questions';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num <= 0) {
                            return 'Must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Shuffle options
                      CheckboxListTile(
                        title: const Text('Shuffle Questions'),
                        value: _shuffleQuestions,
                        onChanged: (value) {
                          setState(() {
                            _shuffleQuestions = value ?? false;
                          });
                        },
                        activeColor: AppColors.buttonPrimary,
                      ),
                      CheckboxListTile(
                        title: const Text('Shuffle Answers'),
                        value: _shuffleAnswers,
                        onChanged: (value) {
                          setState(() {
                            _shuffleAnswers = value ?? false;
                          });
                        },
                        activeColor: AppColors.buttonPrimary,
                      ),
                      const SizedBox(height: 24),

                      // Scope selector
                      Text(
                        'Scope *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      groupsAsync.when(
                        data: (groups) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                title: const Text('All Groups'),
                                value: _isForAllGroups,
                                onChanged: (value) {
                                  setState(() {
                                    _isForAllGroups = value ?? true;
                                    if (_isForAllGroups) {
                                      _selectedGroupIds.clear();
                                    }
                                  });
                                },
                                activeColor: AppColors.buttonPrimary,
                              ),
                              if (!_isForAllGroups && groups.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: groups.length,
                                    itemBuilder: (context, index) {
                                      final group = groups[index];
                                      final isSelected = _selectedGroupIds
                                          .contains(group.id);
                                      return CheckboxListTile(
                                        title: Text(group.name),
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value ?? false) {
                                              _selectedGroupIds.add(group.id);
                                            } else {
                                              _selectedGroupIds.remove(
                                                group.id,
                                              );
                                            }
                                          });
                                        },
                                        activeColor: AppColors.buttonPrimary,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Error loading groups'),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.inter()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            widget.quiz == null ? 'Create' : 'Update',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
