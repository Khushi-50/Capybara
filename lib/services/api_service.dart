import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/quest_models.dart';
import '../models/user_model.dart';

class ApiService {
  // iOS Simulator uses localhost. Port 5050 as per your backend.
  final String baseUrl = "http://localhost:5050/api";
  final storage = const FlutterSecureStorage();

  /// Syncs XP and Streak back to MongoDB
  Future<void> syncStats(int xp, int streak) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/user/sync"),
        headers: await _getHeaders(),
        body: json.encode({'xp': xp, 'streak': streak}),
      );
    } catch (e) {
      debugPrint("Stats Sync Error: $e");
    }
  }

  /// Handles user registration and returns the token
  Future<String?> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/signup"), // Sync with your Node.js route
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': name,
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        if (token != null) {
          await storage.write(key: 'auth_token', value: token);
        }
        return token;
      }
    } catch (e) {
      debugPrint("Signup API Error: $e");
    }
    return null;
  }

  /// Handles user login and returns the token
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/user/login"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        if (token != null) {
          await storage.write(key: 'auth_token', value: token);
        }
        return token;
      }
    } catch (e) {
      debugPrint("Login API Error: $e");
    }
    return null;
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- 1. LEARNING & MAP DATA ---
  Future<FullChapterModel?> getChapter(String lang, int chapterId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/learning/courses/$chapterId/map?lang=$lang"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return FullChapterModel.fromJson(json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Map Fetch Error: $e");
    }
    return null;
  }

  Future<List<QuizQuestion>> getQuizQuestions(String quizId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/learning/quizzes/$quizId/questions"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((q) => QuizQuestion.fromJson(q)).toList();
      }
    } catch (e) {
      debugPrint("Quiz Fetch Error: $e");
    }
    return [];
  }

  // --- 2. USER PROFILE & STATS ---
  Future<UserModel?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user/profile"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data['user']);
      }
    } catch (e) {
      debugPrint("Profile Fetch Error: $e");
    }
    return null;
  }

  // UPDATED: Syncs the completion status to MongoDB
  Future<void> syncProgress(int subtopicId, bool isCorrect) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/user/progress"),
        headers: await _getHeaders(),
        body: json.encode({
          'question_id': subtopicId, // Matching your mongoose schema
          'status': isCorrect ? 'completed' : 'failed',
          'is_correct': isCorrect,
        }),
      );
    } catch (e) {
      debugPrint("Progress Sync Error: $e");
    }
  }
}
