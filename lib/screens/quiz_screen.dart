import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/appcolors.dart';
import '../widgets/cyber_button.dart';
import '../providers/quest_provider.dart';
import '../models/quest_models.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String title;
  final int subtopicId;

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
  final PageController _pageController = PageController();

  void _handleAction() async {
    if (!_isAnswerChecked) {
      // Step 1: Check the answer visually
      if (_selectedIndex != null) {
        setState(() => _isAnswerChecked = true);
      }
    } else {
      // Step 2: Handle transition or Finish
      if (_currentPage < widget.questions.length - 1) {
        // Move to next question
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage++;
          _selectedIndex = null;
          _isAnswerChecked = false;
        });
      } else {
        // --- THE HANDSHAKE ---
        // Final question finished. Update MongoDB and Profile.
        final provider = Provider.of<QuestProvider>(context, listen: false);

        // We assume 'true' for completion logic here.
        // You could calculate a score if needed.
        await provider.completeSubtopic(widget.subtopicId, true);

        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Moved progress logic inside build so it updates on every setstate
    double progress = (_currentPage + 1) / widget.questions.length;
    final currentQuestion = widget.questions[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Keep them focused on the quiz
        title: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          color: AppColors.primary,
          minHeight: 8,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Force using the button
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentQuestion.question,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Option Cards
                      ...List.generate(
                        currentQuestion.options.length,
                        (i) => _buildOptionCard(i, currentQuestion),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: CyberButton(
              label: _isAnswerChecked
                  ? (_currentPage == widget.questions.length - 1
                        ? "FINISH"
                        : "CONTINUE")
                  : "CHECK",
              onPressed: _selectedIndex != null ? _handleAction : () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, QuizQuestion question) {
    bool isSelected = _selectedIndex == index;
    bool isCorrect = question.options[index] == question.answer;

    // Define border colors based on selection and reveal state
    Color borderColor = Colors.white10;
    if (isSelected) borderColor = AppColors.primary;

    if (_isAnswerChecked) {
      if (isCorrect) {
        borderColor = Colors.greenAccent;
      } else if (isSelected) {
        borderColor = Colors.redAccent;
      }
    }

    return GestureDetector(
      onTap: _isAnswerChecked
          ? null // Lock input after checking
          : () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 2),
          // Added subtle Cyber-Glow when revealed
          boxShadow: [
            if (_isAnswerChecked && isCorrect)
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            if (_isAnswerChecked && isSelected && !isCorrect)
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            // Option Index (1, 2, 3...)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white60,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 15),

            // The Option Text
            Expanded(
              child: Text(
                question.options[index],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            // Success Icon
            if (_isAnswerChecked && isCorrect)
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            // Error Icon
            if (_isAnswerChecked && isSelected && !isCorrect)
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}
