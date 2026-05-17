import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/resource_suggestion_service.dart';
import 'resource_feedback_repository.dart';

class SharedPreferencesResourceFeedbackRepository
    implements ResourceFeedbackRepository {
  const SharedPreferencesResourceFeedbackRepository({
    required SharedPreferencesAsync preferences,
  }) : _preferences = preferences;

  static const feedbackKey = 'journal.resource_feedback.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<Map<String, ResourceFeedbackAction>> loadAll() async {
    final raw = await _preferences.getString(feedbackKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, Object?>) {
      return {};
    }

    final feedback = <String, ResourceFeedbackAction>{};

    decoded.forEach((resourceId, actionValue) {
      if (actionValue is! String) {
        return;
      }

      final action = _parseAction(actionValue);
      if (action == null) {
        return;
      }

      feedback[resourceId] = action;
    });

    return feedback;
  }

  @override
  Future<void> save({
    required String resourceId,
    required ResourceFeedbackAction action,
  }) async {
    final current = await loadAll();
    current[resourceId] = action;

    final payload = <String, String>{
      for (final entry in current.entries)
        entry.key: _encodeAction(entry.value),
    };

    await _preferences.setString(feedbackKey, jsonEncode(payload));
  }

  ResourceFeedbackAction? _parseAction(String value) {
    return switch (value) {
      'save' => ResourceFeedbackAction.save,
      'dismiss' => ResourceFeedbackAction.dismiss,
      'not_helpful' => ResourceFeedbackAction.notHelpful,
      _ => null,
    };
  }

  String _encodeAction(ResourceFeedbackAction action) {
    return switch (action) {
      ResourceFeedbackAction.save => 'save',
      ResourceFeedbackAction.dismiss => 'dismiss',
      ResourceFeedbackAction.notHelpful => 'not_helpful',
    };
  }
}
