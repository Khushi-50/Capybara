import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quiz_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/learning_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final String quizId;
  final String quizTitle;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final LearningService _service = LearningService(ApiClient());
  QuizPayload? _quizPayload;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _index = 0;
  final Map<String, String> _selected = {};
  final Set<String> _revealed = {};
  QuizSubmitResult? _result;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final token = context.read<AuthProvider>().token;
    try {
      final payload = await _service.getQuizQuestions(widget.quizId, token);
      setState(() {
        _quizPayload = payload;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleNext() async {
    final currentQuestion = _quizPayload?.questions[_index];
    if (currentQuestion == null) return;
    if (!_revealed.contains(currentQuestion.id)) return;

    if (_index < (_quizPayload!.questions.length - 1)) {
      setState(() => _index += 1);
      return;
    }

    setState(() => _isSubmitting = true);

    final token = context.read<AuthProvider>().token;
    final answers = _quizPayload!.questions
        .map((question) => {
              'questionId': question.id,
              'selectedAnswer': _selected[question.id] ?? '',
            })
        .toList();

    try {
      final result = await _service.submitQuiz(widget.quizId, answers, token);
      await context.read<AuthProvider>().updateStats(totalXp: result.totalXp);
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_result != null) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.quizTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Correct: ${_result!.correctAnswers}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Incorrect: ${_result!.incorrectAnswers}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Earned XP: ${_result!.earnedXp}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Total XP: ${_result!.totalXp}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Back to Path',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _quizPayload!.questions[_index];
    final selected = _selected[question.id];
    final isRevealed = _revealed.contains(question.id);
    final isCorrect = selected == question.correctAnswer;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Back to Path'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_index + 1} / ${_quizPayload!.questions.length}', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(widget.quizTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Text(question.questionText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              ...question.options.map((option) {
                Color border = AppColors.border;
                Color background = AppColors.surface;

                if (isRevealed && option == question.correctAnswer) {
                  border = AppColors.green;
                  background = AppColors.green.withOpacity(0.16);
                } else if (isRevealed && selected == option && option != question.correctAnswer) {
                  border = AppColors.red;
                  background = AppColors.red.withOpacity(0.14);
                } else if (selected == option) {
                  border = AppColors.cyan;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: isRevealed
                        ? null
                        : () {
                            setState(() {
                              _selected[question.id] = option;
                              _revealed.add(question.id);
                            });
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: background,
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(option),
                    ),
                  ),
                );
              }),
              if (isRevealed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isCorrect ? AppColors.green : AppColors.red).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isCorrect ? 'Correct' : 'Incorrect', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      if (!isCorrect) ...[
                        const SizedBox(height: 6),
                        Text('Correct answer: ${question.correctAnswer}'),
                      ],
                      const SizedBox(height: 6),
                      Text('XP value: ${question.xpValue}'),
                    ],
                  ),
                ),
              const Spacer(),
              PrimaryButton(
                label: _isSubmitting
                    ? 'Submitting...'
                    : _index == _quizPayload!.questions.length - 1
                        ? 'Finish Quiz'
                        : 'Next Question',
                isLoading: _isSubmitting,
                onPressed: _handleNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
