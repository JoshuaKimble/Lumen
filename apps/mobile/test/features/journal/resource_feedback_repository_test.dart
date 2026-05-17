import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/shared_preferences_resource_feedback_repository.dart';
import 'package:lumen/src/features/journal/domain/resource_suggestion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('saves and loads resource feedback actions', () async {
    final repository = SharedPreferencesResourceFeedbackRepository(
      preferences: SharedPreferencesAsync(),
    );

    await repository.save(
      resourceId: 'resource-1',
      action: ResourceFeedbackAction.save,
    );
    await repository.save(
      resourceId: 'resource-2',
      action: ResourceFeedbackAction.dismiss,
    );

    final loaded = await repository.loadAll();
    expect(loaded['resource-1'], ResourceFeedbackAction.save);
    expect(loaded['resource-2'], ResourceFeedbackAction.dismiss);
  });
}
