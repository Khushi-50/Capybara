import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/quest_models.dart';
import '../models/user_model.dart';
import '../screens/quiz_screen.dart';

const _kXp = 'local_xp';
const _kStreak = 'local_streak';
const _kHearts = 'local_hearts';
const _kLastActiveDate = 'last_active_date';
const _kQuestionsAnsweredToday = 'questions_answered_today';

class QuestProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  QuestProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _syncToDatabase();
    }
  }

  // ── STATE ──────────────────────────────────────────────────────────────────
  UserModel? _user;
  int _xp = 0;
  int _streak = 0;
  int _hearts = 5;
  int _questionsAnsweredToday = 0;
  bool _didActivityToday = false;
  String _currentLanguage = 'c-programming';
  bool _isLoading = false;

  List<FullChapterModel> _courseMap = [];
  List<QuizQuestion> _currentQuestions = [];
  List<UserModel> _leaderboard = [];

  // Local session cache so map updates instantly after quiz
  final Set<String> _locallyCompleted = {};

  // ── GETTERS ────────────────────────────────────────────────────────────────
  UserModel? get user => _user;
  int get xp => _xp;
  int get streak => _streak;
  int get hearts => _hearts;
  int get questionsAnsweredToday => _questionsAnsweredToday;
  bool get didActivityToday => _didActivityToday; // ← the missing getter
  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  List<FullChapterModel> get courseMap => _courseMap;
  List<QuizQuestion> get currentQuestions => _currentQuestions;
  List<UserModel> get leaderboard => _leaderboard;

  List<String> get _allSubtopicIds => _courseMap
      .expand((chapter) => chapter.subtopics)
      .map((s) => s.subtopicId)
      .toList();

  // ── LOAD ───────────────────────────────────────────────────────────────────
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    await _loadFromPrefs();

    try {
      final fetchedUser = await _apiService.getProfile();
      if (fetchedUser != null) {
        _user = fetchedUser;
        if (fetchedUser.xp >= _xp) _xp = fetchedUser.xp;
      }

      List<FullChapterModel> tempMap = [];
      for (int i = 1; i <= 10; i++) {
        final chapterData = await _apiService.getChapter(_currentLanguage, i);
        if (chapterData != null) tempMap.add(chapterData);
      }
      if (tempMap.isEmpty) tempMap.add(_generateLocalTestChapter());
      _courseMap = tempMap;

      await _saveToPrefs();
    } catch (e) {
      debugPrint("Data Load Error: $e");
      if (_courseMap.isEmpty) _courseMap = [_generateLocalTestChapter()];
    }

    _updateStreakFromDate();
    _isLoading = false;
    notifyListeners();
  }

  // ── SHARED PREFERENCES ─────────────────────────────────────────────────────
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt(_kXp) ?? 0;
    _streak = prefs.getInt(_kStreak) ?? 0;
    _hearts = prefs.getInt(_kHearts) ?? 5;
    _questionsAnsweredToday = prefs.getInt(_kQuestionsAnsweredToday) ?? 0;

    final lastActive = prefs.getString(_kLastActiveDate);
    final todayStr = _todayString();
    _didActivityToday = lastActive == todayStr && _questionsAnsweredToday > 0;

    if (lastActive != null && lastActive != todayStr) {
      _questionsAnsweredToday = 0;
      await prefs.setInt(_kQuestionsAnsweredToday, 0);
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kXp, _xp);
    await prefs.setInt(_kStreak, _streak);
    await prefs.setInt(_kHearts, _hearts);
    await prefs.setInt(_kQuestionsAnsweredToday, _questionsAnsweredToday);
    await prefs.setString(_kLastActiveDate, _todayString());
  }

  Future<void> _syncToDatabase() async {
    try {
      await _apiService.syncStats(_xp, _streak);
    } catch (e) {
      debugPrint("DB sync error: $e");
    }
  }

  void _updateStreakFromDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getString(_kLastActiveDate);
    final today = _todayString();
    final yesterday = _yesterdayString();

    if (lastActive != null && lastActive != today && lastActive != yesterday) {
      _streak = 0;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  // ── UNLOCK LOGIC ───────────────────────────────────────────────────────────
  String getSubtopicStatus(String subtopicId) {
    final allIds = _allSubtopicIds;
    if (allIds.isEmpty) return 'locked';

    final index = allIds.indexOf(subtopicId);
    if (index == -1) return 'locked';

    if (index == 0) {
      return _isSubtopicCompleted(subtopicId) ? 'completed' : 'unlocked';
    }

    final prevId = allIds[index - 1];
    if (!_isSubtopicCompleted(prevId)) return 'locked';
    return _isSubtopicCompleted(subtopicId) ? 'completed' : 'unlocked';
  }

  bool _isSubtopicCompleted(String subtopicId) {
    if (_locallyCompleted.contains(subtopicId)) return true;
    if (_user == null) return false;
    return _user!.progress.any(
      (p) => p.questionId == subtopicId && p.status == 'completed',
    );
  }

  // ── START QUIZ ─────────────────────────────────────────────────────────────
  // quizLength: cap questions per sitting (default 7)
  Future<void> startQuiz(
    BuildContext context,
    String subtopicId,
    String subtopicName,
    List<QuizQuestion> fallbackQuestions, {
    int quizLength = 7, // ← the missing named parameter
  }) async {
    _isLoading = true;
    notifyListeners();

    List<QuizQuestion> questions = [];
    try {
      final fetched = await _apiService.getSubtopicQuestions(subtopicId);
      questions = fetched.isNotEmpty ? fetched : fallbackQuestions;
    } catch (e) {
      debugPrint("Quiz fetch error: $e");
      questions = fallbackQuestions;
    }

    // Always exactly quizLength questions
    if (questions.length > quizLength) {
      questions = questions.take(quizLength).toList();
    }
    _currentQuestions = questions;

    _isLoading = false;
    notifyListeners();

    if (_currentQuestions.isNotEmpty && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            questions: _currentQuestions,
            title: subtopicName,
            subtopicId: subtopicId,
          ),
        ),
      );
    }
  }

  // ── COMPLETE SUBTOPIC ──────────────────────────────────────────────────────
  Future<void> completeSubtopic(
    String subtopicId,
    bool isCorrect,
    int xpEarned,
  ) async {
    if (isCorrect) {
      _locallyCompleted.add(subtopicId);
      _xp += xpEarned;
      if (_streak == 0) _streak = 1;
      _didActivityToday = true;
      _questionsAnsweredToday += 7;
    }
    notifyListeners();
    await _saveToPrefs();

    // Background sync — don't block UI
    _syncToDatabase();
    _apiService.syncProgress(subtopicId, isCorrect).then((_) async {
      final updatedUser = await _apiService.getProfile();
      if (updatedUser != null) {
        _user = updatedUser;
        if (updatedUser.xp > _xp) {
          _xp = updatedUser.xp;
          await _saveToPrefs();
        }
      }
      notifyListeners();
    });
  }

  // ── AUTH ───────────────────────────────────────────────────────────────────
  Future<bool> handleLogin(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final token = await _apiService.login(email, password);
    if (token != null) await loadUserData();
    _isLoading = false;
    notifyListeners();
    return token != null;
  }

  Future<void> logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    _xp = 0;
    _streak = 0;
    _hearts = 5;
    _questionsAnsweredToday = 0;
    _didActivityToday = false;
    _locallyCompleted.clear();
    _courseMap = [];
    notifyListeners();
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayString() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  FullChapterModel _generateLocalTestChapter() {
    return FullChapterModel(
      course: 'C Programming',
      chapter: 1,
      chapterName: 'The Skeleton (Program Structure)',
      subtopics: [
        SubtopicFolder(
          subtopicId: '1',
          subtopicName: 'The Entry Point',
          quizzes: [
            QuizSubtopic(
              quizId: '1',
              quizTitle: 'Meet main()',
              questions: [
                QuizQuestion(
                  id: 1,
                  question: 'Every C program starts from?',
                  options: ['start()', 'main()', 'run()'],
                  answer: 'main()',
                  xp: 5,
                ),
                QuizQuestion(
                  id: 2,
                  question: 'main() is a?',
                  options: ['Variable', 'Function', 'Operator'],
                  answer: 'Function',
                  xp: 5,
                ),
                QuizQuestion(
                  id: 3,
                  question: 'How many main() allowed?',
                  options: ['1', '2', 'Many'],
                  answer: '1',
                  xp: 5,
                ),
                QuizQuestion(
                  id: 4,
                  question: 'Correct syntax?',
                  options: ['main{}', 'main()', 'main[]'],
                  answer: 'main()',
                  xp: 5,
                ),
                QuizQuestion(
                  id: 5,
                  question: 'If main() missing?',
                  options: ['Runs', 'Error', 'Ignored'],
                  answer: 'Error',
                  xp: 7,
                ),
                QuizQuestion(
                  id: 6,
                  question: 'main() returns?',
                  options: ['int', 'char', 'float'],
                  answer: 'int',
                  xp: 7,
                ),
                QuizQuestion(
                  id: 7,
                  question: 'Program ends when?',
                  options: ['main ends', 'printf', 'include'],
                  answer: 'main ends',
                  xp: 5,
                ),
              ],
            ),
          ],
        ),
        SubtopicFolder(
          subtopicId: '2',
          subtopicName: 'Curly Braces {}',
          quizzes: [],
        ),
        SubtopicFolder(
          subtopicId: '3',
          subtopicName: '#include & Headers',
          quizzes: [],
        ),
        SubtopicFolder(
          subtopicId: '4',
          subtopicName: 'Putting It Together',
          quizzes: [],
        ),
      ],
    );
  }
}
