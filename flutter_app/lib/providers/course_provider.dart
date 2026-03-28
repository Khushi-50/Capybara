import 'package:flutter/foundation.dart';

import '../models/course_models.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_client.dart';
import '../services/learning_service.dart';
import 'auth_provider.dart';

class CourseProvider extends ChangeNotifier {
  final LearningService _service = LearningService(ApiClient());

  AuthProvider? _auth;
  List<CourseSummary> courses = const [];
  CourseMap? courseMap;
  List<LeaderboardEntry> leaderboard = const [];
  bool isLoading = false;
  String? selectedCourseId;

  void attachAuth(AuthProvider auth) {
    _auth = auth;
  }

  Future<void> loadHome() async {
    final token = _auth?.token ?? '';
    if (token.isEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      courses = await _service.getCourses(token);
      selectedCourseId ??= _auth?.session?.selectedCourse.firstOrNull ?? (courses.isNotEmpty ? (courses.first.slug.isNotEmpty ? courses.first.slug : courses.first.id) : null);

      if (selectedCourseId != null) {
        courseMap = await _service.getCourseMap(selectedCourseId!, token);
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCourse(String courseId) async {
    final token = _auth?.token ?? '';
    if (token.isEmpty) return;

    selectedCourseId = courseId;
    isLoading = true;
    notifyListeners();

    try {
      courseMap = await _service.getCourseMap(courseId, token);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard() async {
    final token = _auth?.token ?? '';
    if (token.isEmpty) return;

    leaderboard = await _service.getLeaderboard(token);
    notifyListeners();
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
