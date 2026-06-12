import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:inner_breeze/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:inner_breeze/models/session.dart';
import 'package:inner_breeze/models/preferences.dart';
import 'package:inner_breeze/models/user.dart';

extension DateTimeRounding on DateTime {
  DateTime roundToNearestMinute() {
    int roundMinutes = minute;
    if (second >= 30) {
      roundMinutes++;
    }
    return DateTime(year, month, day, hour, roundMinutes, 0);
  }
}

class UserProvider with ChangeNotifier {
  User user = User(id: '', preferences: Preferences(), sessions: []);
  Map<int, Duration> roundDurations = {};

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) {
      user = User(id: Uuid().v4(), preferences: Preferences());
    } else {
      final userJson = prefs.getString(userId);
      user = userJson != null
          ? User.fromJson(jsonDecode(userJson))
          : User(id: userId, preferences: Preferences());
    }
    prefs.setString(user.id, jsonEncode(user.toJson()));
    prefs.setString('userId', user.id);
  }

  Future<void> markTutorialAsComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setBool('${user.id}/tutorialComplete', true);
  }

  Future<bool> hasValidSessionId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? sessionId = prefs.getString('${user.id}/currentSession');
    return sessionId != null;
  }

  Future<Session?> loadSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionJson =
        prefs.getString('${user.id}/sessions/${user.currentSessionId}');
    if (sessionJson != null) {
      Session session = Session.fromJson(jsonDecode(sessionJson));
      return session;
    }
    return null;
  }

  Future<Map<String, dynamic>> _loadData(
      List<String> keys, String prefix) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> loadedData = {};
    for (var key in keys) {
      dynamic value = prefs.get('$prefix/$key');
      if (value != null) {
        loadedData[key] = value;
      }
    }
    return loadedData;
  }

  Future<void> _saveData(Map<String, dynamic> data, String prefix) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var key in data.keys) {
      var value = data[key];
      if (value is int) {
        prefs.setInt('$prefix/$key', value);
      } else if (value is String) {
        prefs.setString('$prefix/$key', value);
      } else if (value is bool) {
        prefs.setBool('$prefix/$key', value);
      }
    }
  }

  Future<Preferences> loadUserPreferences(List<String> keys) async {
    Map<String, dynamic> data = await _loadData(keys, user.id);
    return Preferences.fromJson(data);
  }

  Future<void> saveUserPreferences(Preferences preferences) async {
    await _saveData(preferences.toJson(), user.id);
  }

  Future<String> startNewSession([DateTime? dateTime]) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime sessionDateTime = dateTime?.roundToNearestMinute() ??
        DateTime.now().roundToNearestMinute();
    int timestamp =
        sessionDateTime.millisecondsSinceEpoch; // Convert to timestamp
    String sessionId = timestamp.toString();
    Session session = Session(id: sessionId, rounds: {});
    prefs.setString(
        '${user.id}/sessions/$sessionId', jsonEncode(session.toJson()));
    user.currentSessionId = sessionId;
    notifyListeners();
    return sessionId;
  }

  Future<void> saveSessionData(Session session) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        '${user.id}/sessions/${session.id}', jsonEncode(session.toJson()));
  }

  Future<void> convertOldSessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (key.startsWith('${user.id}/sessions/')) {
        var sessionJson = prefs.getString(key);
        if (sessionJson != null) {
          var sessionData = jsonDecode(sessionJson);
          if (sessionData.containsKey('dateTime')) {
            DateTime oldDateTime = DateTime.parse(sessionData['dateTime']);
            DateTime roundedDateTime = oldDateTime.roundToNearestMinute();
            String newSessionId = roundedDateTime.toIso8601String();

            if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z$')
                .hasMatch(sessionData['id'])) {
              sessionData['id'] = newSessionId;
              prefs.remove(key);
              prefs.setString(
                  '${user.id}/sessions/$newSessionId', jsonEncode(sessionData));
            }
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>> getAllData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> allData = {};

    allData['preferences'] = user.preferences.toJson();

    List<Map<String, dynamic>> sessionList = [];
    final allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (key.startsWith('${user.id}/sessions/')) {
        var sessionJson = prefs.getString(key);
        if (sessionJson != null) {
          Map<String, dynamic> sessionData = jsonDecode(sessionJson);

          sessionData.remove('userId');

          sessionList.add(sessionData);
        }
      }
    }
    allData['sessions'] = sessionList;

    return allData;
  }

  Future<void> importData(Map<String, dynamic> importedData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (importedData.containsKey('preferences')) {
      var preferencesJson = importedData['preferences'];
      if (preferencesJson is Map<String, dynamic>) {
        Preferences importedPreferences = Preferences.fromJson(preferencesJson);
        await saveUserPreferences(importedPreferences);
      } else {
        print('Invalid format for preferences data');
      }
    }

    // Import sessions
    if (importedData.containsKey('sessions')) {
      var sessionsList = importedData['sessions'];
      if (sessionsList is List) {
        for (var sessionJson in sessionsList) {
          if (sessionJson is Map<String, dynamic>) {
            if (sessionJson.containsKey('dateTime')) {
              DateTime oldDateTime =
                  DateTime.tryParse(sessionJson['dateTime']) ?? DateTime.now();
              DateTime roundedDateTime = oldDateTime.roundToNearestMinute();
              int timestamp = roundedDateTime.millisecondsSinceEpoch;
              String sessionId = timestamp.toString();
              sessionJson['id'] = sessionId;
            }

            Session importedSession = Session.fromJson(sessionJson);
            await prefs.setString('${user.id}/sessions/${importedSession.id}',
                jsonEncode(importedSession.toJson()));
          } else {
            print('Invalid format for session data');
          }
        }
      } else {
        print('Invalid format for sessions data');
      }
    }

    notifyListeners();
  }

  Future<String> getLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('languagePreference') ??
        'en'; // Default to 'en' if not set
  }

  Future<void> setLanguagePreference(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languagePreference', languageCode);
    if (appKey.currentState != null) {
      await appKey.currentState!.initializeLocale();
    }
    notifyListeners();
  }

  Future<void> moveRoundToSession(
      String oldSessionId, int roundNumber, int newTimestamp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Session? oldSession = (prefs
                .getString('${user.id}/sessions/$oldSessionId') !=
            null)
        ? Session.fromJson(
            jsonDecode(prefs.getString('${user.id}/sessions/$oldSessionId')!))
        : null;

    String newSessionId = newTimestamp.toString();
    Session newSession = (prefs
                .getString('${user.id}/sessions/$newSessionId') !=
            null)
        ? Session.fromJson(
            jsonDecode(prefs.getString('${user.id}/sessions/$newSessionId')!))
        : Session(id: newSessionId, rounds: {});

    if (oldSession != null && oldSession.rounds.containsKey(roundNumber)) {
      int newRoundNumber = newSession.rounds.isEmpty
          ? 1
          : newSession.rounds.keys.reduce(max) + 1;
      newSession.rounds[newRoundNumber] = oldSession.rounds[roundNumber]!;
      oldSession.rounds.remove(roundNumber);

      saveSessionData(oldSession);
      saveSessionData(newSession);
    }

    notifyListeners();
  }

  Future<void> updateRoundDuration(
      String sessionId, int roundNumber, Duration newDuration) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionJson = prefs.getString('${user.id}/sessions/$sessionId');
    if (sessionJson == null) return;

    Session session = Session.fromJson(jsonDecode(sessionJson));
    if (session.rounds.containsKey(roundNumber)) {
      session.rounds[roundNumber] = newDuration;
    }

    saveSessionData(session);
    notifyListeners();
  }

  Future<Map<int, Duration>> loadRoundDurations() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson =
        prefs.getString('${user.id}/sessions/${user.currentSessionId}');
    if (sessionJson == null) return {};
    final sessionData = Session.fromJson(jsonDecode(sessionJson));
    return sessionData.rounds;
  }

  Future<void> deleteSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionJson =
        prefs.getString('${user.id}/sessions/${user.currentSessionId}');
    if (sessionJson == null) return;
    Session session = Session.fromJson(jsonDecode(sessionJson));
    Set<String> allKeys = prefs.getKeys();
    for (String key in allKeys) {
      if (key
          .startsWith('${user.id}/sessions/${user.currentSessionId}/rounds/')) {
        prefs.remove(key);
      }
    }
    session.rounds = {};
    saveSessionData(session);
    notifyListeners();
  }

  Future<void> deleteRound(int roundNumber, [String? sessionId]) async {
    final prefs = await SharedPreferences.getInstance();
    String? finalSessionId = sessionId ?? user.currentSessionId;
    String? sessionJson =
        prefs.getString('${user.id}/sessions/$finalSessionId');
    if (sessionJson == null) return;
    Session session = Session.fromJson(jsonDecode(sessionJson));
    session.rounds.remove(roundNumber);
    Map<int, Duration> updatedRounds = {};
    for (var entry in session.rounds.entries) {
      if (entry.key > roundNumber) {
        updatedRounds[entry.key - 1] = entry.value;
      } else {
        updatedRounds[entry.key] = entry.value;
      }
    }
    session.rounds = updatedRounds;
    saveSessionData(session);
  }

  Future<List<Session>> getAllSessions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    List<Session> sessions = [];
    for (String key in allKeys) {
      if (key.startsWith('${user.id}/sessions/')) {
        var sessionJson = prefs.getString(key);
        if (sessionJson != null) {
          var sessionData = jsonDecode(sessionJson);
          if (sessionData['rounds'].length > 0) {
            sessions.add(Session.fromJson(sessionData));
          }
        }
      }
    }
    sessions.sort((a, b) {
      int timestampA = int.tryParse(a.id) ?? 0;
      int timestampB = int.tryParse(b.id) ?? 0;
      return timestampB.compareTo(timestampA);
    });

    return sessions;
  }
}
