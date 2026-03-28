class UserSession {
  const UserSession({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
    this.totalXp = 0,
    this.weeklyXp = 0,
    this.streak = 0,
    this.selectedCourse = const [],
  });

  final String id;
  final String username;
  final String email;
  final String token;
  final int totalXp;
  final int weeklyXp;
  final int streak;
  final List<String> selectedCourse;

  UserSession copyWith({
    String? id,
    String? username,
    String? email,
    String? token,
    int? totalXp,
    int? weeklyXp,
    int? streak,
    List<String>? selectedCourse,
  }) {
    return UserSession(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      token: token ?? this.token,
      totalXp: totalXp ?? this.totalXp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      streak: streak ?? this.streak,
      selectedCourse: selectedCourse ?? this.selectedCourse,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'token': token,
      'totalXp': totalXp,
      'weeklyXp': weeklyXp,
      'streak': streak,
      'selectedCourse': selectedCourse,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      totalXp: (json['totalXp'] ?? json['total_xp'] ?? 0) as int,
      weeklyXp: (json['weeklyXp'] ?? json['weekly_xp'] ?? 0) as int,
      streak: (json['streak'] ?? 0) as int,
      selectedCourse: ((json['selectedCourse'] ?? []) as List).map((item) => item.toString()).toList(),
    );
  }
}
