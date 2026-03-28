class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionNumber,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.xpValue,
  });

  final String id;
  final int questionNumber;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final int xpValue;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      questionNumber: (json['question_number'] ?? 0) as int,
      questionText: json['question_text']?.toString() ?? '',
      options: ((json['options'] ?? []) as List).map((item) => item.toString()).toList(),
      correctAnswer: json['correct_answer']?.toString() ?? '',
      xpValue: (json['xp_value'] ?? 0) as int,
    );
  }
}

class QuizPayload {
  const QuizPayload({
    required this.title,
    required this.questions,
  });

  final String title;
  final List<QuizQuestion> questions;

  factory QuizPayload.fromJson(Map<String, dynamic> json) {
    final quiz = json['quiz'] as Map<String, dynamic>? ?? {};
    return QuizPayload(
      title: quiz['quiz_title']?.toString() ?? '',
      questions: (json['questions'] as List? ?? [])
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizSubmitResult {
  const QuizSubmitResult({
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.earnedXp,
    required this.totalXp,
  });

  final int correctAnswers;
  final int incorrectAnswers;
  final int earnedXp;
  final int totalXp;

  factory QuizSubmitResult.fromJson(Map<String, dynamic> json) {
    final stats = json['user_stats'] as Map<String, dynamic>? ?? {};
    return QuizSubmitResult(
      correctAnswers: (json['correct_answers'] ?? 0) as int,
      incorrectAnswers: (json['incorrect_answers'] ?? 0) as int,
      earnedXp: (json['earned_xp'] ?? 0) as int,
      totalXp: (stats['total_xp'] ?? 0) as int,
    );
  }
}
