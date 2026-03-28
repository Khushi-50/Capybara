class CourseSummary {
  const CourseSummary({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
  });

  final String id;
  final String title;
  final String slug;
  final String description;

  factory CourseSummary.fromJson(Map<String, dynamic> json) {
    return CourseSummary(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class CourseMap {
  const CourseMap({
    required this.courseTitle,
    required this.chapters,
  });

  final String courseTitle;
  final List<ChapterNode> chapters;

  factory CourseMap.fromJson(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>? ?? {};
    final chapters = (json['chapters'] as List? ?? [])
        .map((item) => ChapterNode.fromJson(item as Map<String, dynamic>))
        .toList();

    return CourseMap(
      courseTitle: course['title']?.toString() ?? '',
      chapters: chapters,
    );
  }
}

class ChapterNode {
  const ChapterNode({
    required this.id,
    required this.chapterNumber,
    required this.chapterName,
    required this.completedSubtopics,
    required this.totalSubtopics,
    required this.isCompleted,
    required this.subtopics,
  });

  final String id;
  final int chapterNumber;
  final String chapterName;
  final int completedSubtopics;
  final int totalSubtopics;
  final bool isCompleted;
  final List<SubtopicNode> subtopics;

  factory ChapterNode.fromJson(Map<String, dynamic> json) {
    return ChapterNode(
      id: json['id']?.toString() ?? '',
      chapterNumber: (json['chapter_number'] ?? 0) as int,
      chapterName: json['chapter_name']?.toString() ?? '',
      completedSubtopics: (json['completed_subtopics'] ?? 0) as int,
      totalSubtopics: (json['total_subtopics'] ?? 0) as int,
      isCompleted: (json['is_completed'] ?? false) as bool,
      subtopics: (json['subtopics'] as List? ?? [])
          .map((item) => SubtopicNode.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubtopicNode {
  const SubtopicNode({
    required this.id,
    required this.name,
    required this.completedQuizzes,
    required this.totalQuizzes,
    required this.quizzes,
  });

  final String id;
  final String name;
  final int completedQuizzes;
  final int totalQuizzes;
  final List<QuizNode> quizzes;

  factory SubtopicNode.fromJson(Map<String, dynamic> json) {
    return SubtopicNode(
      id: json['id']?.toString() ?? '',
      name: json['subtopic_name']?.toString() ?? '',
      completedQuizzes: (json['completed_quizzes'] ?? 0) as int,
      totalQuizzes: (json['total_quizzes'] ?? 0) as int,
      quizzes: (json['quizzes'] as List? ?? [])
          .map((item) => QuizNode.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizNode {
  const QuizNode({
    required this.id,
    required this.quizNumber,
    required this.title,
    required this.completedQuestions,
    required this.failedQuestions,
    required this.totalQuestions,
    required this.totalXp,
    required this.isCompleted,
    required this.isUnlocked,
  });

  final String id;
  final int quizNumber;
  final String title;
  final int completedQuestions;
  final int failedQuestions;
  final int totalQuestions;
  final int totalXp;
  final bool isCompleted;
  final bool isUnlocked;

  factory QuizNode.fromJson(Map<String, dynamic> json) {
    return QuizNode(
      id: json['id']?.toString() ?? '',
      quizNumber: (json['quiz_number'] ?? 0) as int,
      title: json['quiz_title']?.toString() ?? '',
      completedQuestions: (json['completed_questions'] ?? 0) as int,
      failedQuestions: (json['failed_questions'] ?? 0) as int,
      totalQuestions: (json['total_questions'] ?? 0) as int,
      totalXp: (json['total_xp'] ?? 0) as int,
      isCompleted: (json['is_completed'] ?? false) as bool,
      isUnlocked: (json['is_unlocked'] ?? false) as bool,
    );
  }
}
