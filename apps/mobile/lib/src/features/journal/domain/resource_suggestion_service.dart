import 'related_resource.dart';

enum ResourceFeedbackAction { save, dismiss, notHelpful }

abstract interface class ResourceSuggestionService {
  Future<List<RelatedResource>> suggest({
    required String text,
    List<String> themeIds = const [],
  });

  Future<void> submitFeedback({
    required String resourceId,
    required ResourceFeedbackAction action,
    String? entryId,
    String? themeId,
  });
}
