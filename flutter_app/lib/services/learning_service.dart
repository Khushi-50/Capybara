import '../models/course_models.dart';
import '../models/leaderboard_entry.dart';
import '../models/quiz_models.dart';
import 'api_client.dart';

class LearningService {
  LearningService(this._client);

  final ApiClient _client;

  Future<List<CourseSummary>> getCourses(String token) async {
    final data = await _client.get('/api/learning/courses', token: token) as Map<String, dynamic>;
    return (data['courses'] as List? ?? [])
        .map((item) => CourseSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CourseMap> getCourseMap(String courseId, String token) async {
    final data = await _client.get('/api/learning/courses/$courseId/map', token: token)
        as Map<String, dynamic>;
    return CourseMap.fromJson(data);
  }

  Future<QuizPayload> getQuizQuestions(String quizId, String token) async {
    final data = await _client.get('/api/learning/quizzes/$quizId/questions', token: token)
        as Map<String, dynamic>;
    return QuizPayload.fromJson(data);
  }

  Future<QuizSubmitResult> submitQuiz(
    String quizId,
    List<Map<String, dynamic>> answers,
    String token,
  ) async {
    final data = await _client.post(
      '/api/learning/quizzes/$quizId/submit',
      {'answers': answers},
      token: token,
    ) as Map<String, dynamic>;

    return QuizSubmitResult.fromJson(data);
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String token) async {
    final data = await _client.get('/api/user/leaderboard', token: token) as Map<String, dynamic>;
    return (data['leaderboard'] as List? ?? [])
        .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    return await _client.get('/api/user/profile', token: token) as Map<String, dynamic>;
  }
}
