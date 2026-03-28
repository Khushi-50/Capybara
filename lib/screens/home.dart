import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/appcolors.dart';
import '../providers/quest_provider.dart';
import '../models/quest_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // This triggers the data fetch from MongoDB immediately when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuestProvider>(context, listen: false).loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildMapContent(context, provider),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickyHeader(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(BuildContext context, QuestProvider provider) {
    // 1. If we are loading and have no data yet, show a spinner
    if (provider.isLoading && provider.courseMap.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // 2. If loading failed and we have no data, show a retry button
    if (provider.courseMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Unable to connect to Quest Server",
              style: TextStyle(color: Colors.white70),
            ),
            TextButton(
              onPressed: () => provider.loadUserData(),
              child: const Text(
                "RETRY CONNECTION",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 220),

          ...provider.courseMap.map((chapter) {
            return Column(
              children: [
                _buildChapterHeader(chapter.chapterName),

                ...chapter.subtopics.asMap().entries.map((entry) {
                  int index = entry.key;
                  var subtopic = entry.value;

                  String status = provider.getSubtopicStatus(
                    subtopic.subtopicId,
                  );
                  bool isLocked = status == 'locked';

                  Alignment alignment = Alignment.center;
                  if (index % 4 == 1) alignment = Alignment.centerLeft;
                  if (index % 4 == 3) alignment = Alignment.centerRight;

                  return Column(
                    children: [
                      Align(
                        alignment: alignment,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: _buildProgressNode(
                            context,
                            subtopic: subtopic,
                            status: status,
                          ),
                        ),
                      ),
                      _buildConnector(isLocked: isLocked),
                    ],
                  );
                }).toList(),
              ],
            );
          }).toList(),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildProgressNode(
    BuildContext context, {
    required SubtopicFolder subtopic,
    required String status,
  }) {
    final provider = Provider.of<QuestProvider>(context, listen: false);
    bool isLocked = status == 'locked';
    bool isCompleted = status == 'completed';

    return Opacity(
      opacity: isLocked ? 0.4 : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCompleted)
            const SizedBox(
              width: 95,
              height: 95,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ),

          _buildMapNode(
            label: subtopic.subtopicName,
            isLocked: isLocked,
            type: isCompleted ? 'star' : (isLocked ? 'lock' : 'play'),
            onTap: () {
              if (!isLocked && subtopic.quizzes.isNotEmpty) {
                provider.startQuiz(
                  context,
                  subtopic.quizzes.first.quizId.toString(),
                  subtopic.subtopicName,
                  subtopic.subtopicId,
                  subtopic.quizzes.first.questions,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildChapterHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildConnector({required bool isLocked}) {
    return Container(
      width: 4,
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isLocked ? Colors.white.withOpacity(0.05) : Colors.white10,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context, QuestProvider questData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CodeQuest",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _statChip("🔥", "${questData.streak}"),
                  const SizedBox(width: 12),
                  _statChip("💎", "${questData.xp}"),
                  const SizedBox(width: 12),
                  _statChip("❤️", "${questData.hearts}"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildProgressCard(questData),
        ],
      ),
    );
  }

  Widget _buildProgressCard(QuestProvider provider) {
    String chapterName = provider.courseMap.isNotEmpty
        ? provider.courseMap.first.chapterName
        : "Loading Modules...";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CURRENT MODULE",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  chapterName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapNode({
    required String label,
    required bool isLocked,
    required String type,
    VoidCallback? onTap,
  }) {
    IconData icon;
    if (type == 'lock')
      icon = Icons.lock_outline;
    else if (type == 'star')
      icon = Icons.auto_awesome;
    else
      icon = Icons.play_arrow_rounded;

    Color color = isLocked ? Colors.grey[900]! : AppColors.secondary;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: isLocked
                  ? Border.all(color: Colors.white10, width: 2)
                  : null,
              boxShadow: isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.secondaryGlow.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
            ),
            child: Icon(
              icon,
              color: isLocked ? Colors.white10 : Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isLocked ? Colors.white12 : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String emoji, String count) => Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 4),
      Text(
        count,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
