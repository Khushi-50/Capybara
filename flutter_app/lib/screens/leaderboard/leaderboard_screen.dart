import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/course_provider.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Weekly Rank',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Top 3 heroes and the next 7 challengers',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ...provider.leaderboard.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  leading: Text(
                    '#${entry.rank}',
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  title: Text(entry.username),
                  subtitle: Text('Weekly ${entry.weeklyXp} XP'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${entry.totalXp} XP', style: const TextStyle(color: AppColors.cyan)),
                      Text('Streak ${entry.streak}', style: const TextStyle(color: AppColors.textMuted)),
                    ],
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
