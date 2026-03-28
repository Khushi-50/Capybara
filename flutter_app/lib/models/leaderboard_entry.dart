class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.weeklyXp,
    required this.totalXp,
    required this.streak,
  });

  final int rank;
  final String username;
  final int weeklyXp;
  final int totalXp;
  final int streak;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] ?? 0) as int,
      username: json['username']?.toString() ?? '',
      weeklyXp: (json['weekly_xp'] ?? 0) as int,
      totalXp: (json['total_xp'] ?? 0) as int,
      streak: (json['streak'] ?? 0) as int,
    );
  }
}
