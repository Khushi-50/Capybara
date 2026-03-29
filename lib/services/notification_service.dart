import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

// Notification IDs — fixed so we can cancel/replace specific ones
const int _kStreakNudgeId = 101;
const int _kMissYouId = 102;
const int _kKeepGoingId = 103;
const int _kQuizWinId = 200; // base; actual = 200 + Random

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── INIT ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  // ── CALLED ON EVERY APP OPEN ───────────────────────────────────────────────
  // Cancels stale nudges, then reschedules based on whether the user
  // has already been active today.
  Future<void> onAppOpen({required bool didActivityToday, required int streak}) async {
    // Cancel all pending scheduled notifications
    await _plugin.cancel(_kStreakNudgeId);
    await _plugin.cancel(_kMissYouId);
    await _plugin.cancel(_kKeepGoingId);

    if (didActivityToday) {
      // They've already done something today — cheer them on to do more
      await _scheduleMotivation();
    } else if (streak > 0) {
      // They have a streak going but haven't done anything yet today —
      // warn them sooner (8h) so they don't break it
      await _scheduleStreakWarning(hoursFromNow: 8, streak: streak);
    } else {
      // Cold user — send a gentle "miss you" in 24h
      await _scheduleMissYou(hoursFromNow: 24);
    }
  }

  // ── CALLED WHEN APP GOES TO BACKGROUND ────────────────────────────────────
  // If the user has a streak at risk and hasn't done today's activity,
  // fire a more urgent nudge in 4h.
  Future<void> onAppBackground({required bool didActivityToday, required int streak}) async {
    if (!didActivityToday && streak > 0) {
      await _plugin.cancel(_kStreakNudgeId);
      await _scheduleStreakWarning(hoursFromNow: 4, streak: streak);
    }
  }

  // ── INSTANT WIN NOTIFICATION (fires immediately after quiz finish) ─────────
  Future<void> showQuizWin({required String topicName, required int xpEarned}) async {
    final messages = [
      'You just earned $xpEarned XP on "$topicName"! 🚀',
      'Logic unlocked: $topicName. +$xpEarned XP added! 🧠',
      'One step closer to the leaderboard! +$xpEarned XP 🏆',
      'Your brain just got an upgrade. +$xpEarned XP ✨',
    ];
    final body = messages[Random().nextInt(messages.length)];

    await _plugin.show(
      _kQuizWinId + Random().nextInt(50),
      'Quest Complete! 🎉',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quiz_win_channel',
          'Quiz Wins',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ── PRIVATE SCHEDULERS ─────────────────────────────────────────────────────

  Future<void> _scheduleStreakWarning({required int hoursFromNow, required int streak}) async {
    final messages = [
      "Your $streak-day streak is at risk! 🔥 Just 5 mins keeps it alive.",
      "Don't lose your $streak-day streak! Quick quiz before midnight?",
      "$streak days strong — don't let today break it! 💪",
    ];
    final body = messages[Random().nextInt(messages.length)];

    await _plugin.zonedSchedule(
      _kStreakNudgeId,
      "Streak Alert! 🔥",
      body,
      tz.TZDateTime.now(tz.local).add(Duration(hours: hoursFromNow)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_channel',
          'Streak Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleMotivation() async {
    final messages = [
      "You're already ahead today! Squeeze in one more quiz? 🎯",
      "Great session! One more lesson and you could climb the leaderboard. 📈",
      "You're on a roll! Keep building that momentum. 🚀",
    ];
    final body = messages[Random().nextInt(messages.length)];

    // Fire 6 hours after opening — when they might be idle again
    await _plugin.zonedSchedule(
      _kKeepGoingId,
      "Keep the momentum! 💎",
      body,
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 6)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation_channel',
          'Motivation',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleMissYou({required int hoursFromNow}) async {
    final messages = [
      "The Logic Jungle misses you! 🦫 Take a quick quiz?",
      "Your capybara is lonely. Come back for 5 mins? 🦫",
      "Did you forget about CodeQuest? We saved your progress!",
    ];
    final body = messages[Random().nextInt(messages.length)];

    await _plugin.zonedSchedule(
      _kMissYouId,
      "We miss you! 👋",
      body,
      tz.TZDateTime.now(tz.local).add(Duration(hours: hoursFromNow)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nudge_channel',
          'Daily Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
