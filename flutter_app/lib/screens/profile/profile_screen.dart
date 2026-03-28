import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_chip.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final session = auth.session;
    final initial = (session?.username.isNotEmpty ?? false) ? session!.username[0].toUpperCase() : 'Q';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: AppColors.purple,
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 18),
                Text(session?.username ?? 'CodeQuest Hero', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(session?.email ?? 'quester@example.com', style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                const Text('Learning Code', style: TextStyle(color: AppColors.yellow, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    StatChip(label: 'Total XP', value: '${session?.totalXp ?? 0}'),
                    StatChip(label: 'Day Streak', value: '${session?.streak ?? 0}'),
                    const StatChip(label: 'Hearts', value: '5'),
                    StatChip(label: 'Active', value: ((session?.selectedCourse.firstOrNull ?? 'C').toUpperCase())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _ProfileTile(icon: Icons.person, label: 'Account'),
            const _ProfileTile(icon: Icons.emoji_events, label: 'Show on Leaderboard'),
            const _ProfileTile(icon: Icons.notifications, label: 'Push Notifications'),
            _ProfileTile(
              icon: Icons.logout,
              label: 'Log Out',
              textColor: AppColors.red,
              onTap: auth.logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.textColor = AppColors.text,
  });

  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        onTap: onTap == null
            ? null
            : () async {
                await onTap!.call();
              },
        leading: Icon(icon, color: textColor == AppColors.text ? AppColors.cyan : textColor),
        title: Text(label, style: TextStyle(color: textColor)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
