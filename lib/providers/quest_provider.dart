import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../models/quest_models.dart';
import '../models/user_model.dart';
import '../screens/quiz_screen.dart';

class QuestProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  QuestProvider() {
    loadUserData();
  }

  // --- 1. STATE VARIABLES ---
  UserModel? _user;
  int _xp = 0;
  int _streak = 0;
  int _hearts = 5;
  String _currentLanguage = 'C';
  bool _isLoading = false;

  List<FullChapterModel> _courseMap = [];
  List<QuizQuestion> _currentQuestions = [];
  List<UserModel> _leaderboard = [];

  // --- 2. GETTERS ---
  UserModel? get user => _user;
  int get xp => _xp;
  int get streak => _streak;
  int get hearts => _hearts;
  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  List<FullChapterModel> get courseMap => _courseMap;
  List<QuizQuestion> get currentQuestions => _currentQuestions;
  List<UserModel> get leaderboard => _leaderboard;

  // --- 3. CORE DATA LOADING ---
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedUser = await _apiService.getProfile();
      if (fetchedUser != null) {
        _user = fetchedUser;
        _xp = fetchedUser.xp;
      }

      List<FullChapterModel> tempMap = [];
      for (int i = 1; i <= 3; i++) {
        final chapterData = await _apiService.getChapter(_currentLanguage, i);
        if (chapterData != null) tempMap.add(chapterData);
      }

      // If API fails or is empty, use the Local Fallback
      if (tempMap.isEmpty) {
        tempMap.add(_generateLocalTestChapter());
      }

      _courseMap = tempMap;
    } catch (e) {
      debugPrint("Data Load Error: $e");
      if (_courseMap.isEmpty) _courseMap = [_generateLocalTestChapter()];
    }

    _isLoading = false;
    notifyListeners();
  }

  FullChapterModel _generateLocalTestChapter() {
    return FullChapterModel(
      course: _currentLanguage,
      chapter: 1,
      chapterName: "Module 1: Getting Started",
      subtopics: [
        SubtopicFolder(
          subtopicId: 1,
          subtopicName: "The Entry Point",
          quizzes: [
            // Updated to match your QuizSubtopic constructor
            QuizSubtopic(
              quizId: 101,
              quizTitle: "Basics Quiz",
              questions: [
                QuizQuestion(
                  id: 1,
                  question: "What is the entry point of a C program?",
                  options: ["start()", "main()", "begin()", "init()"],
                  answer: "main()",
                  xp: 10,
                ),
              ],
            ),
          ],
        ),
        SubtopicFolder(
          subtopicId: 2,
          subtopicName: "Variables & Types",
          quizzes: [
            QuizSubtopic(
              quizId: 102,
              quizTitle: "Variables Quiz",
              questions: [], // Empty list is fine to avoid errors
            ),
          ],
        ),
      ],
    );
  }

  // --- 4. PROGRESS & MAP LOGIC ---
  String getSubtopicStatus(int subtopicId) {
    if (_user == null) {
      return subtopicId == 1 ? 'unlocked' : 'locked';
    }

    // Check if subtopic is in the user's progress list
    final progressEntry = _user!.progress.firstWhere(
      (p) => p.questionId == subtopicId.toString(),
      orElse: () => UserProgress(questionId: '', status: 'locked'),
    );

    if (subtopicId == 1 && progressEntry.status == 'locked') return 'unlocked';
    return progressEntry.status;
  }

  Future<void> completeSubtopic(int subtopicId, bool isCorrect) async {
    _isLoading = true;
    notifyListeners();

    await _apiService.syncProgress(subtopicId, isCorrect);

    // Refreshing profile ensures the UI reflects the new 'completed' status
    final updatedUser = await _apiService.getProfile();
    if (updatedUser != null) {
      _user = updatedUser;
      _xp = updatedUser.xp;
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- 5. QUIZ NAVIGATION ---
  Future<void> startQuiz(
    BuildContext context,
    String quizId,
    String subtopicName,
    int subtopicId,
    List<QuizQuestion> fallbackQuestions,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // If using a local/test ID, skip the API call to avoid Mongoose ObjectId errors
      if (quizId == "101" || quizId == "102" || quizId.startsWith("test")) {
        _currentQuestions = fallbackQuestions;
      } else {
        _currentQuestions = await _apiService.getQuizQuestions(quizId);
      }
    } catch (e) {
      debugPrint("Quiz fetch error: $e");
      _currentQuestions = fallbackQuestions;
    }

    _isLoading = false;
    notifyListeners();

    if (_currentQuestions.isNotEmpty) {
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

  // --- 6. AUTH & OTHER ---
  Future<bool> handleLogin(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final token = await _apiService.login(email, password);
    if (token != null) await loadUserData();
    _isLoading = false;
    notifyListeners();
    return token != null;
  }

  void addXP(int amount) async {
    _xp += amount;
    notifyListeners();
    await _apiService.syncStats(_xp, _streak);
  }
}
