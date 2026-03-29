import 'package:flutter/material.dart';
import 'package:hackmol7/providers/quest_provider.dart';
import 'package:provider/provider.dart';
import '../ui/appcolors.dart';
import '../widgets/cyber_button.dart';
import '../models/quest_models.dart';
import '../services/notification_service.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String title;
  final String subtopicId;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.title,
    required this.subtopicId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentPage = 0;
  int? _selectedIndex;
  bool _isAnswerChecked = false;
  int _correctCount = 0;
  int _totalXpEarned = 0;
  final PageController _pageController = PageController();

  // ── BACK BUTTON HANDLING ───────────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    // If already on first question with nothing selected, let them leave freely
    if (_currentPage == 0 && _selectedIndex == null) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave the quiz?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your progress in this quiz will be lost. You can restart it anytime.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'STAY',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'LEAVE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  // ── MAIN FLOW ──────────────────────────────────────────────────────────────
  void _handleCheck() {
    if (_selectedIndex == null) return;
    final question = widget.questions[_currentPage];
    final isCorrect = question.options[_selectedIndex!] == question.answer;
    if (isCorrect) {
      _correctCount++;
      _totalXpEarned += question.xp;
    }
    setState(() => _isAnswerChecked = true);
  }

  void _handleContinue() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage++;
      _selectedIndex = null;
      _isAnswerChecked = false;
    });
  }

  Future<void> _handleFinish() async {
    final provider = Provider.of<QuestProvider>(context, listen: false);
    final passed = _correctCount >= (widget.questions.length * 0.6).ceil();

    // 1. Update provider — this saves to SharedPrefs AND syncs to DB
    await provider.completeSubtopic(widget.subtopicId, passed, _totalXpEarned);

    // 2. Fire the dopamine notification
    if (passed) {
      await NotificationService().showQuizWin(
        topicName: widget.title,
        xpEarned: _totalXpEarned,
      );
    }

    if (mounted) {
      // 3. Show result screen instead of just popping
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _ResultDialog(
          correctCount: _correctCount,
          totalCount: widget.questions.length,
          xpEarned: _totalXpEarned,
          passed: passed,
          onContinue: () => Navigator.pop(context),
        ),
      );
      if (mounted) Navigator.pop(context); // back to map
    }
  }

  void _handleAction() {
    if (!_isAnswerChecked) {
      _handleCheck();
    } else if (_currentPage < widget.questions.length - 1) {
      _handleContinue();
    } else {
      _handleFinish();
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / widget.questions.length;
    final currentQuestion = widget.questions[_currentPage];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () async {
              if (await _onWillPop()) Navigator.pop(context);
            },
          ),
          title: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: AppColors.primary,
            minHeight: 8,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentPage + 1}/${widget.questions.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Topic label
                        Text(
                          widget.title.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // XP badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '+${currentQuestion.xp} XP',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Question text
                        Text(
                          currentQuestion.question,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Options
                        ...List.generate(
                          currentQuestion.options.length,
                          (i) => _buildOptionCard(i, currentQuestion),
                        ),

                        // Feedback message after checking
                        if (_isAnswerChecked) _buildFeedback(currentQuestion),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom action area
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(QuizQuestion question) {
    final isCorrect = question.options[_selectedIndex!] == question.answer;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.greenAccent.withOpacity(0.1)
            : Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect
              ? Colors.greenAccent.withOpacity(0.4)
              : Colors.redAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct! +${question.xp} XP' : 'Not quite!',
                  style: TextStyle(
                    color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isCorrect)
                  Text(
                    'Answer: ${question.answer}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    String label;
    if (!_isAnswerChecked) {
      label = 'CHECK';
    } else if (_currentPage < widget.questions.length - 1) {
      label = 'CONTINUE';
    } else {
      label = 'FINISH';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score indicator
          if (_correctCount > 0 || _isAnswerChecked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalXpEarned XP earned so far',
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ],
              ),
            ),
          CyberButton(
            label: label,
            onPressed: _selectedIndex != null || _isAnswerChecked
                ? _handleAction
                : () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, QuizQuestion question) {
    final isSelected = _selectedIndex == index;
    final isCorrect = question.options[index] == question.answer;

    Color borderColor = Colors.white10;
    Color bgColor = AppColors.surface;

    if (isSelected && !_isAnswerChecked) {
      borderColor = AppColors.primary;
    }
    if (_isAnswerChecked) {
      if (isCorrect) {
        borderColor = Colors.greenAccent;
        bgColor = Colors.greenAccent.withOpacity(0.07);
      } else if (isSelected) {
        borderColor = Colors.redAccent;
        bgColor = Colors.redAccent.withOpacity(0.07);
      }
    }

    return GestureDetector(
      onTap: _isAnswerChecked
          ? null
          : () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            // Option letter (A, B, C...)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected && !_isAnswerChecked
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    color: isSelected && !_isAnswerChecked
                        ? AppColors.primary
                        : Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  color: _isAnswerChecked && isCorrect
                      ? Colors.greenAccent
                      : Colors.white,
                  fontSize: 15,
                  fontWeight: _isAnswerChecked && isCorrect
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (_isAnswerChecked && isCorrect)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 20,
              ),
            if (_isAnswerChecked && isSelected && !isCorrect)
              const Icon(
                Icons.cancel_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ── RESULT DIALOG ──────────────────────────────────────────────────────────
class _ResultDialog extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final int xpEarned;
  final bool passed;
  final VoidCallback onContinue;

  const _ResultDialog({
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    required this.passed,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (correctCount / totalCount * 100).round();
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(passed ? '🎉' : '😅', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              passed ? 'Quest Complete!' : 'Keep Practising!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correctCount / $totalCount correct  ($pct%)',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            // XP row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💎', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '+$xpEarned XP',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('earned!', style: TextStyle(color: Colors.amber)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: passed
                      ? AppColors.primary
                      : AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  passed ? 'Back to Map' : 'Try Again',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
