import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesStudyGuideProgressRepository {
  const SharedPreferencesStudyGuideProgressRepository({
    required SharedPreferencesAsync preferences,
  }) : _preferences = preferences;

  static const progressKey = 'journal.study_guide_progress.v1';

  final SharedPreferencesAsync _preferences;

  Future<Map<String, bool>> load(String guideId) async {
    final allProgress = await _loadAll();
    return allProgress[guideId] ?? const <String, bool>{};
  }

  Future<void> save({
    required String guideId,
    required String itemId,
    required bool isCompleted,
  }) async {
    final allProgress = await _loadAll();
    final guideProgress = Map<String, bool>.from(
      allProgress[guideId] ?? const <String, bool>{},
    );
    guideProgress[itemId] = isCompleted;
    allProgress[guideId] = guideProgress;
    await _preferences.setString(progressKey, jsonEncode(allProgress));
  }

  Future<Map<String, Map<String, bool>>> _loadAll() async {
    final raw = await _preferences.getString(progressKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return {};
    }

    final progress = <String, Map<String, bool>>{};

    decoded.forEach((guideId, value) {
      if (value is! Map<String, Object?>) {
        return;
      }

      final guideProgress = <String, bool>{};
      value.forEach((itemId, completedValue) {
        if (completedValue is bool) {
          guideProgress[itemId] = completedValue;
        }
      });
      progress[guideId] = guideProgress;
    });

    return progress;
  }
}
