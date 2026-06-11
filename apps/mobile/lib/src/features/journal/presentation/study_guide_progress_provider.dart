import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/shared_preferences_study_guide_progress_repository.dart';

final studyGuideProgressRepositoryProvider =
    Provider<SharedPreferencesStudyGuideProgressRepository>((ref) {
      return SharedPreferencesStudyGuideProgressRepository(
        preferences: SharedPreferencesAsync(),
      );
    });

final studyGuideProgressProvider =
    FutureProvider.family<Map<String, bool>, String>((ref, guideId) async {
      try {
        return await ref
            .watch(studyGuideProgressRepositoryProvider)
            .load(guideId);
      } catch (_) {
        return {};
      }
    });
