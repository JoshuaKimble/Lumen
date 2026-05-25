import 'related_resource.dart';
import '../../settings/domain/scripture_app_preference.dart';

enum ResourceFeedbackAction { save, dismiss, notHelpful }

abstract interface class ResourceSuggestionService {
  Future<List<RelatedResource>> suggest({
    required String text,
    List<String> themeIds = const [],
    ScriptureAppPreference preference = ScriptureAppPreference.none,
  });

  Future<void> submitFeedback({
    required String resourceId,
    required ResourceFeedbackAction action,
    String? entryId,
    String? themeId,
  });
}
