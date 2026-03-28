import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../ui/appcolors.dart';
import '../models/user_model.dart';

class RankScreen extends StatefulWidget {
  const RankScreen({super.key});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch fresh data when the user navigates to this tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //   context.read<QuestProvider>().fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuestProvider>();
    final currentUser = provider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Leaderboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: provider.leaderboard.isEmpty && provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _buildLeaderboardContent(provider, currentUser),
    );
  }

  Widget _buildLeaderboardContent(
    QuestProvider provider,
    UserModel? currentUser,
  ) {
    final topThree = provider.leaderboard.take(3).toList();
    final theRest = provider.leaderboard.skip(3).toList();

    return Column(
      children: [
        const Text(
          "Top coders this week",
          style: TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 30),

        // --- THE PODIUM ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (topThree.length > 1)
                _buildPodiumItem(
                  topThree[1],
                  "2nd",
                  110,
                  Colors.grey[400]!,
                ), // Silver
              const SizedBox(width: 10),
              if (topThree.isNotEmpty)
                _buildPodiumItem(topThree[0], "1st", 150, Colors.amber), // Gold
              const SizedBox(width: 10),
              if (topThree.length > 2)
                _buildPodiumItem(
                  topThree[2],
                  "3rd",
                  90,
                  Colors.orangeAccent,
                ), // Bronze
            ],
          ),
        ),

        const SizedBox(height: 25),

        // --- THE LIST ---
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 100),
              itemCount: theRest.length,
              itemBuilder: (context, index) {
                final user = theRest[index];
                // DYNAMIC IDENTIFICATION: Compare IDs or Usernames
                bool isMe = user.username == currentUser?.username;
                return _buildUserTile(user, index + 4, isMe);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumItem(
    UserModel user,
    String rank,
    double height,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : "U",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user.username,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        Text(
          "${user.xp} XP",
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 10),
        Container(
          width: 85,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.9), color.withOpacity(0.4)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Center(
            child: Text(
              rank.substring(0, 1),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(UserModel user, int rank, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isMe ? AppColors.primary : Colors.white10,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 25,
            child: Text(
              "$rank",
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary.withOpacity(0.3),
            child: Text(
              user.username[0].toUpperCase(),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username + (isMe ? " (You)" : ""),
                  style: TextStyle(
                    color: isMe ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Level ${user.xp ~/ 100}", // Simple level logic based on XP
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            "${user.xp} XP",
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
