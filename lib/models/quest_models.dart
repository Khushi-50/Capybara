// quest_models.dart
// All IDs are Strings because MongoDB ObjectIds come back as strings from the API.

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final String answer;
  final int xp;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.xp,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['question_number'] ?? json['id'] ?? 0,
      // Backend uses 'question_text', JSON files use 'question'
      question: json['question_text'] ?? json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      // Backend uses 'correct_answer', JSON files use 'answer'
      answer: json['correct_answer'] ?? json['answer'] ?? '',
      xp: json['xp_value'] ?? json['xp'] ?? 0,
    );
  }
}

class QuizSubtopic {
  final String quizId;
  final String quizTitle;
  final List<QuizQuestion> questions;

  QuizSubtopic({
    required this.quizId,
    required this.quizTitle,
    required this.questions,
  });

  factory QuizSubtopic.fromJson(Map<String, dynamic> json) {
    // Backend sends 'id' (ObjectId), local JSON sends 'quiz_id'
    final rawQuestions =
        (json['questions'] ?? json['quizzes'] ?? []) as List;

    return QuizSubtopic(
      quizId: json['id']?.toString() ?? json['quiz_id']?.toString() ?? '0',
      quizTitle: json['quiz_title'] ?? '',
      questions: rawQuestions
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubtopicFolder {
  // String ID so it works with MongoDB ObjectId strings from the API
  final String subtopicId;
  final String subtopicName;
  final List<QuizSubtopic> quizzes;

  SubtopicFolder({
    required this.subtopicId,
    required this.subtopicName,
    required this.quizzes,
  });

  factory SubtopicFolder.fromJson(Map<String, dynamic> json) {
    return SubtopicFolder(
      // Backend map sends 'id', local JSON sends 'subtopic_id'
      subtopicId:
          json['id']?.toString() ?? json['subtopic_id']?.toString() ?? '0',
      subtopicName: json['subtopic_name'] ?? '',
      quizzes: (json['quizzes'] as List? ?? [])
          .map((z) => QuizSubtopic.fromJson(z as Map<String, dynamic>))
          .toList(),
    );
  }

  // Convenience: all questions across every quiz in this subtopic node,
  // used as the offline fallback when API is unreachable
  List<QuizQuestion> get allQuestions =>
      quizzes.expand((q) => q.questions).toList();
}

class FullChapterModel {
  final String course;
  final int chapter;
  final String chapterName;
  final List<SubtopicFolder> subtopics;

  FullChapterModel({
    required this.course,
    required this.chapter,
    required this.chapterName,
    required this.subtopics,
  });

  factory FullChapterModel.fromJson(Map<String, dynamic> json) {
    return FullChapterModel(
      course: json['course'] ?? '',
      chapter: json['chapter'] ?? 0,
      chapterName: json['chapter_name'] ?? '',
      subtopics: (json['subtopics'] as List? ?? [])
          .map((s) => SubtopicFolder.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
