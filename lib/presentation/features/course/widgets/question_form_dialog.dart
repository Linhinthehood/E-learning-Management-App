import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../domain/entities/question_bank_entity.dart';
import '../../../../domain/entities/question_entity.dart';
import '../../../common/styles/colors.dart';
import '../../../providers/question_provider.dart';

/// Dialog for creating or editing a question
class QuestionFormDialog extends ConsumerStatefulWidget {
  final QuestionBankEntity questionBank;
  final QuestionEntity? question;

  const QuestionFormDialog({
    super.key,
    required this.questionBank,
    this.question,
  });

  @override
  ConsumerState<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends ConsumerState<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionTextController;
  late TextEditingController _explanationController;
  late TextEditingController _pointsController;

  QuestionType _selectedType = QuestionType.multipleChoice;
  QuestionDifficulty _selectedDifficulty = QuestionDifficulty.medium;

  // For multiple choice/response
  final List<TextEditingController> _optionControllers = [];
  int? _selectedCorrectAnswer; // For multiple choice
  final Set<int> _selectedCorrectAnswers = {}; // For multiple response

  // For true/false
  String _trueFalseAnswer = 'True';

  // For short answer
  late TextEditingController _shortAnswerController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController(
      text: widget.question?.questionText ?? '',
    );
    _explanationController = TextEditingController(
      text: widget.question?.explanation ?? '',
    );
    _pointsController = TextEditingController(
      text: widget.question?.points.toString() ?? '1',
    );
    _shortAnswerController = TextEditingController();

    if (widget.question != null) {
      _selectedType = widget.question!.type;
      _selectedDifficulty = widget.question!.difficulty;

      if (_selectedType == QuestionType.multipleChoice ||
          _selectedType == QuestionType.multipleResponse) {
        for (var option in widget.question!.options) {
          _optionControllers.add(TextEditingController(text: option));
        }
        if (_selectedType == QuestionType.multipleChoice) {
          _selectedCorrectAnswer = widget.question!.correctAnswerIndex;
        } else {
          if (widget.question!.correctAnswer is List) {
            _selectedCorrectAnswers.addAll(
              (widget.question!.correctAnswer as List).cast<int>(),
            );
          }
        }
      } else if (_selectedType == QuestionType.trueFalse) {
        _trueFalseAnswer = widget.question!.correctAnswerText ?? 'True';
      } else if (_selectedType == QuestionType.shortAnswer) {
        _shortAnswerController.text = widget.question!.correctAnswerText ?? '';
      }
    } else {
      // Initialize with 4 empty options for new questions
      for (int i = 0; i < 4; i++) {
        _optionControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _explanationController.dispose();
    _pointsController.dispose();
    _shortAnswerController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
        // Adjust selected answers if needed
        if (_selectedCorrectAnswer == index) {
          _selectedCorrectAnswer = null;
        } else if (_selectedCorrectAnswer != null &&
            _selectedCorrectAnswer! > index) {
          _selectedCorrectAnswer = _selectedCorrectAnswer! - 1;
        }
        _selectedCorrectAnswers.remove(index);
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate based on question type
    if (_selectedType == QuestionType.multipleChoice) {
      if (_selectedCorrectAnswer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a correct answer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_selectedType == QuestionType.multipleResponse) {
      if (_selectedCorrectAnswers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one correct answer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build options list
      List<String> options = [];
      dynamic correctAnswer;

      if (_selectedType == QuestionType.multipleChoice ||
          _selectedType == QuestionType.multipleResponse) {
        options = _optionControllers.map((c) => c.text.trim()).toList();
        if (_selectedType == QuestionType.multipleChoice) {
          correctAnswer = _selectedCorrectAnswer;
        } else {
          correctAnswer = _selectedCorrectAnswers.toList();
        }
      } else if (_selectedType == QuestionType.trueFalse) {
        options = ['True', 'False'];
        correctAnswer = _trueFalseAnswer;
      } else if (_selectedType == QuestionType.shortAnswer) {
        options = [];
        correctAnswer = _shortAnswerController.text.trim();
      }

      final question = QuestionEntity(
        id: widget.question?.id ?? '',
        questionBankId: widget.questionBank.id,
        questionText: _questionTextController.text.trim(),
        type: _selectedType,
        options: options,
        correctAnswer: correctAnswer,
        difficulty: _selectedDifficulty,
        points: double.tryParse(_pointsController.text) ?? 1.0,
        explanation: _explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim(),
        createdAt: widget.question?.createdAt ?? DateTime.now(),
      );

      if (widget.question == null) {
        await ref.read(questionProvider.notifier).createQuestion(question);
      } else {
        await ref.read(questionProvider.notifier).updateQuestion(question);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 800,
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
                  Flexible(
                    child: Text(
                      widget.question == null
                          ? 'Create Question'
                          : 'Edit Question',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                      // Question Type
                      Text(
                        'Question Type *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<QuestionType>(
                        // ignore: deprecated_member_use
                        value: _selectedType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                        items: QuestionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getQuestionTypeLabel(type)),
                          );
                        }).toList(),
                        onChanged: widget.question == null
                            ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedType = value;
                                    _selectedCorrectAnswer = null;
                                    _selectedCorrectAnswers.clear();
                                  });
                                }
                              }
                            : null, // Disable changing type when editing
                      ),
                      const SizedBox(height: 24),

                      // Question Text
                      Text(
                        'Question Text *',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _questionTextController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          hintText: 'Enter your question here',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a question';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Question type specific fields
                      if (_selectedType == QuestionType.multipleChoice ||
                          _selectedType == QuestionType.multipleResponse)
                        _buildMultipleChoiceFields(),

                      if (_selectedType == QuestionType.trueFalse)
                        _buildTrueFalseFields(),

                      if (_selectedType == QuestionType.shortAnswer)
                        _buildShortAnswerFields(),

                      const SizedBox(height: 24),

                      // Difficulty and Points
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Difficulty *',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<QuestionDifficulty>(
                                  // ignore: deprecated_member_use
                                  value: _selectedDifficulty,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                  items: QuestionDifficulty.values.map((diff) {
                                    return DropdownMenuItem(
                                      value: diff,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 12,
                                            color: _getDifficultyColor(diff),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_getDifficultyLabel(diff)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedDifficulty = value;
                                      });
                                    }
                                  },
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
                                  'Points *',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _pointsController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    hintText: '1',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    final points = double.tryParse(value);
                                    if (points == null || points <= 0) {
                                      return 'Must be > 0';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Explanation
                      Text(
                        'Explanation (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _explanationController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          hintText:
                              'Provide an explanation that will be shown after answering',
                        ),
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
                    onPressed: _isLoading ? null : _saveQuestion,
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
                            widget.question == null ? 'Create' : 'Update',
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

  Widget _buildMultipleChoiceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Answer Options *',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (_optionControllers.length < 10)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Option'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedType == QuestionType.multipleChoice
              ? 'Select one correct answer'
              : 'Select all correct answers',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ..._optionControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          final isCorrect = _selectedType == QuestionType.multipleChoice
              ? _selectedCorrectAnswer == index
              : _selectedCorrectAnswers.contains(index);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio/Checkbox for correct answer
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _selectedType == QuestionType.multipleChoice
                      ? Radio<int>(
                          value: index,
                          // ignore: deprecated_member_use
                          groupValue: _selectedCorrectAnswer,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            setState(() {
                              _selectedCorrectAnswer = value;
                            });
                          },
                          activeColor: Colors.green,
                        )
                      : Checkbox(
                          value: isCorrect,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedCorrectAnswers.add(index);
                              } else {
                                _selectedCorrectAnswers.remove(index);
                              }
                            });
                          },
                          activeColor: Colors.green,
                        ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isCorrect ? Colors.green : AppColors.border,
                          width: isCorrect ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isCorrect ? Colors.green : AppColors.border,
                          width: isCorrect ? 2 : 1,
                        ),
                      ),
                      hintText: 'Option ${index + 1}',
                      suffixIcon: _optionControllers.length > 2
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeOption(index),
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Option cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correct Answer *',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('True'),
                value: 'True',
                // ignore: deprecated_member_use
                groupValue: _trueFalseAnswer,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  setState(() {
                    _trueFalseAnswer = value!;
                  });
                },
                activeColor: Colors.green,
                tileColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _trueFalseAnswer == 'True'
                        ? Colors.green
                        : AppColors.border,
                    width: _trueFalseAnswer == 'True' ? 2 : 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('False'),
                value: 'False',
                // ignore: deprecated_member_use
                groupValue: _trueFalseAnswer,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  setState(() {
                    _trueFalseAnswer = value!;
                  });
                },
                activeColor: Colors.green,
                tileColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _trueFalseAnswer == 'False'
                        ? Colors.green
                        : AppColors.border,
                    width: _trueFalseAnswer == 'False' ? 2 : 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortAnswerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expected Answer *',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The answer students should provide (case-sensitive)',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _shortAnswerController,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            hintText: 'Enter the expected answer',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an expected answer';
            }
            return null;
          },
        ),
      ],
    );
  }

  Color _getDifficultyColor(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return Colors.green;
      case QuestionDifficulty.medium:
        return Colors.orange;
      case QuestionDifficulty.hard:
        return Colors.red;
    }
  }

  String _getDifficultyLabel(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.multipleResponse:
        return 'Multiple Response';
    }
  }
}
