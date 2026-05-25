import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/data/scripture_app_preference_provider.dart';
import '../../settings/domain/scripture_app_preference.dart';
import '../data/resource_feedback_repository.dart';
import '../data/resource_suggestion_service_provider.dart';
import '../data/shared_preferences_resource_feedback_repository.dart';
import '../domain/related_resource.dart';
import '../domain/resource_suggestion_service.dart';

final resourceFeedbackRepositoryProvider = Provider<ResourceFeedbackRepository>(
  (ref) {
    return SharedPreferencesResourceFeedbackRepository(
      preferences: SharedPreferencesAsync(),
    );
  },
);

final resourceFeedbackControllerProvider =
    AsyncNotifierProvider<
      ResourceFeedbackController,
      Map<String, ResourceFeedbackAction>
    >(ResourceFeedbackController.new);

class ResourceFeedbackController
    extends AsyncNotifier<Map<String, ResourceFeedbackAction>> {
  @override
  Future<Map<String, ResourceFeedbackAction>> build() async {
    try {
      return await ref.watch(resourceFeedbackRepositoryProvider).loadAll();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveFeedback({
    required String resourceId,
    required ResourceFeedbackAction action,
  }) async {
    final current =
        state.asData?.value ?? const <String, ResourceFeedbackAction>{};
    final updated = {...current, resourceId: action};
    state = AsyncData(updated);
    try {
      await ref
          .watch(resourceFeedbackRepositoryProvider)
          .save(resourceId: resourceId, action: action);
    } catch (_) {}
  }
}

class ResourceSuggestionQuery {
  const ResourceSuggestionQuery({required this.text, this.themeIds = const []});

  final String text;
  final List<String> themeIds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ResourceSuggestionQuery &&
        other.text == text &&
        _sameThemeIds(other.themeIds, themeIds);
  }

  @override
  int get hashCode => Object.hash(text, Object.hashAll(themeIds));

  bool _sameThemeIds(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}

final resourceSuggestionsProvider =
    FutureProvider.family<List<RelatedResource>, ResourceSuggestionQuery>((
      ref,
      query,
    ) async {
      final preference =
          ref.watch(scriptureAppPreferenceControllerProvider).asData?.value ??
          ScriptureAppPreference.none;
      final suggestions = await ref
          .watch(resourceSuggestionServiceProvider)
          .suggest(
            text: query.text,
            themeIds: query.themeIds,
            preference: preference,
          );
      final feedback =
          ref.watch(resourceFeedbackControllerProvider).asData?.value ??
          const <String, ResourceFeedbackAction>{};

      return suggestions
          .where((resource) {
            final action = feedback[resource.id];
            return action != ResourceFeedbackAction.dismiss &&
                action != ResourceFeedbackAction.notHelpful;
          })
          .toList(growable: false);
    });
