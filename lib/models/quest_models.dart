// 1. Individual Question Level
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
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? '',
      xp: json['xp'] ?? 0,
    );
  }
}

// 2. The Quiz Level (A subtopic has multiple of these)
class QuizSubtopic {
  final int quizId;
  final String quizTitle;
  final List<QuizQuestion> questions;

  QuizSubtopic({
    required this.quizId,
    required this.quizTitle,
    required this.questions,
  });

  factory QuizSubtopic.fromJson(Map<String, dynamic> json) {
    return QuizSubtopic(
      quizId: json['quiz_id'] ?? 0,
      quizTitle: json['quiz_title'] ?? '',
      questions:
          (json['quizzes'] != null) // Handles the nested quizzes key
          ? (json['quizzes'] as List)
                .map((q) => QuizQuestion.fromJson(q))
                .toList()
          : (json['questions'] as List? ?? [])
                .map((q) => QuizQuestion.fromJson(q))
                .toList(),
    );
  }
}

// 3. The Subtopic Level (The Circles/Nodes on your map)
class SubtopicFolder {
  final int subtopicId;
  final String subtopicName;
  final List<QuizSubtopic> quizzes;

  SubtopicFolder({
    required this.subtopicId,
    required this.subtopicName,
    required this.quizzes,
  });

  factory SubtopicFolder.fromJson(Map<String, dynamic> json) {
    return SubtopicFolder(
      subtopicId: json['subtopic_id'] ?? 0,
      subtopicName: json['subtopic_name'] ?? '',
      quizzes: (json['quizzes'] as List? ?? [])
          .map((z) => QuizSubtopic.fromJson(z))
          .toList(),
    );
  }
}

// 4. The Root Level (The entire Chapter)
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
          .map((s) => SubtopicFolder.fromJson(s))
          .toList(),
    );
  }
}
