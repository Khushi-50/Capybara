import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_session.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _storageKey = 'codequest_flutter_session';

  final AuthService _authService = AuthService(ApiClient());

  UserSession? _session;
  bool _isReady = false;

  bool get isReady => _isReady;
  bool get isLoggedIn => _session != null;
  UserSession? get session => _session;
  String get token => _session?.token ?? '';

  Future<void> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw != null) {
      _session = UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _session = await _authService.login(email, password);
    await _persist();
    notifyListeners();
  }

  Future<void> signup(String username, String email, String password) {
    return _authService.signup(username, email, password);
  }

  Future<void> logout() async {
    _session = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    notifyListeners();
  }

  Future<void> updateStats({int? totalXp, int? weeklyXp, int? streak}) async {
    if (_session == null) return;

    _session = _session!.copyWith(
      totalXp: totalXp,
      weeklyXp: weeklyXp,
      streak: streak,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile({String? username, String? email, List<String>? selectedCourse}) async {
    if (_session == null) return;

    _session = _session!.copyWith(
      username: username,
      email: email,
      selectedCourse: selectedCourse,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_session == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(_session!.toJson()));
  }
}
