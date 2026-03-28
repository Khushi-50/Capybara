import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/path_node.dart';
import '../quiz/quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final currentChapter = courseProvider.courseMap?.chapters
        .cast<ChapterNode?>()
        .firstWhere((chapter) => !(chapter?.isCompleted ?? true), orElse: () => courseProvider.courseMap?.chapters.firstOrNull);

    final chapterProgress = _chapterProgress(currentChapter);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: courseProvider.loadHome,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CodeQuest',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _HeaderStat(icon: Icons.local_fire_department, color: const Color(0xFFFF8B38), value: '${auth.session?.streak ?? 0}'),
                      _HeaderStat(icon: Icons.diamond, color: const Color(0xFF69D3FF), value: '0'),
                      _HeaderStat(icon: Icons.star, color: AppColors.yellow, value: '${auth.session?.totalXp ?? 0}'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment, color: Colors.white70),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURRENT CHAPTER',
                                  style: TextStyle(
                                    color: AppColors.green.withOpacity(0.95),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentChapter?.chapterName ?? 'Loading Quest...',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: chapterProgress / 100,
                          backgroundColor: AppColors.surfaceMuted,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final course = courseProvider.courses[index];
                    final courseId = course.slug.isNotEmpty ? course.slug : course.id;
                    final isSelected = courseProvider.selectedCourseId == courseId;

                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(course.title),
                      onSelected: (_) => courseProvider.selectCourse(courseId),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: courseProvider.courses.length,
                ),
              ),
              const SizedBox(height: 20),
              if (courseProvider.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (courseProvider.courseMap == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No course map found yet.'),
                  ),
                )
              else
                ...courseProvider.courseMap!.chapters.map((chapter) => _ChapterSection(chapter: chapter)),
            ],
          ),
        ),
      ),
    );
  }

  int _chapterProgress(ChapterNode? chapter) {
    if (chapter == null) return 0;
    final totals = chapter.subtopics.fold<Map<String, int>>(
      {'total': 0, 'completed': 0},
      (acc, subtopic) {
        acc['total'] = (acc['total'] ?? 0) + subtopic.totalQuizzes;
        acc['completed'] = (acc['completed'] ?? 0) + subtopic.completedQuizzes;
        return acc;
      },
    );

    return ((totals['completed']! / (totals['total'] == 0 ? 1 : totals['total']!)) * 100).round();
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(value),
        ],
      ),
    );
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({required this.chapter});

  final ChapterNode chapter;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chapter ${chapter.chapterNumber}',
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              chapter.chapterName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ...chapter.subtopics.asMap().entries.map((entry) {
              final subtopicIndex = entry.key;
              final subtopic = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtopic.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subtopic.completedQuizzes}/${subtopic.totalQuizzes} quizzes completed',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    ...subtopic.quizzes.asMap().entries.map((quizEntry) {
                      final quizIndex = quizEntry.key;
                      final quiz = quizEntry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            PathNode(
                              icon: quiz.isCompleted
                                  ? Icons.check
                                  : quizIndex == 0
                                      ? Icons.star
                                      : quizIndex == 1
                                          ? Icons.card_giftcard
                                          : Icons.flash_on,
                              title: 'Quiz ${quiz.quizNumber}',
                              locked: false,
                              offset: quizIndex.isEven ? 0 : (subtopicIndex.isEven ? -72 : 72),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => QuizScreen(
                                      quizId: quiz.id,
                                      quizTitle: quiz.title,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    quiz.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Correct ${quiz.completedQuestions}/${quiz.totalQuestions}',
                                    style: const TextStyle(color: AppColors.textMuted),
                                  ),
                                  Text(
                                    'Failed ${quiz.failedQuestions} | XP ${quiz.totalXp}',
                                    style: const TextStyle(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
