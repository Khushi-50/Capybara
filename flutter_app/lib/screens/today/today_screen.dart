import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;

    final tasks = [
      ('Opened the app today', session?.streak != null ? 'Done' : 'Started'),
      ('Current XP in profile', '${session?.totalXp ?? 0} XP'),
      ('Learning path is active', 'Ready'),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Today',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Good job today. Your completed tasks are shown below.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: const [
                    Icon(Icons.check_circle, color: AppColors.green, size: 34),
                    SizedBox(height: 12),
                    Text('Good Job', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text(
                      'You showed up today. Keep the streak going.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...tasks.map(
              (task) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: AppColors.cyan),
                  title: Text(task.$1),
                  subtitle: Text(task.$2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
